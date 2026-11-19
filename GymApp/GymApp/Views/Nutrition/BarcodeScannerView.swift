import SwiftUI
import AVFoundation

public struct BarcodeScannerView: UIViewControllerRepresentable {
    public var onBarcodeDetected: (String) -> Void
    @Environment(\.presentationMode) var presentationMode

    public init(onBarcodeDetected: @escaping (String) -> Void) {
        self.onBarcodeDetected = onBarcodeDetected
    }

    public func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public final class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView

        init(parent: BarcodeScannerView) {
            self.parent = parent
        }

        public func didFindCode(_ code: String) {
            parent.onBarcodeDetected(code)
            parent.presentationMode.wrappedValue.dismiss()
        }

        public func didCancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

public protocol ScannerViewControllerDelegate: AnyObject {
    func didFindCode(_ code: String)
    func didCancel()
}

public final class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    public weak var delegate: ScannerViewControllerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentDevice: AVCaptureDevice?
    private var hasDetected = false
    private var isTorchOn = false

    private let overlayView = UIView()
    private let targetFrameView = UIView()
    private let scanLineView = UIView()
    private let instructionLabel = UILabel()
    private let torchButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkPermissionsAndSetup()
    }

    private func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
            setupOverlayUI()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                        self?.setupOverlayUI()
                    } else {
                        self?.showPermissionDenied()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDenied()
        @unknown default:
            showPermissionDenied()
        }
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        // Target wide-angle camera on back (optimal for iPhone 16 Pro Max macro/barcode distance)
        let deviceDiscovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )

        guard let device = deviceDiscovery.devices.first ?? AVCaptureDevice.default(for: .video) else {
            showPermissionDenied(message: "Kamera-Hardware nicht verfuegbar.")
            return
        }
        self.currentDevice = device

        do {
            try device.lockForConfiguration()
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isAutoFocusRangeRestrictionSupported {
                device.autoFocusRangeRestriction = .near
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {}

        guard let videoInput = try? AVCaptureDeviceInput(device: device) else { return }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean13,
                .ean8,
                .upce,
                .code128,
                .code39,
                .code93,
                .qr,
                .dataMatrix
            ]
        } else {
            return
        }

        self.captureSession = session

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func setupOverlayUI() {
        // Overlay container
        overlayView.frame = view.bounds
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        overlayView.isUserInteractionEnabled = true
        view.addSubview(overlayView)

        // Target Box Frame
        let boxWidth: CGFloat = 280
        let boxHeight: CGFloat = 160
        targetFrameView.frame = CGRect(
            x: (view.bounds.width - boxWidth) / 2,
            y: (view.bounds.height - boxHeight) / 2 - 40,
            width: boxWidth,
            height: boxHeight
        )
        targetFrameView.layer.borderColor = UIColor(red: 0.494, green: 0.624, blue: 0.522, alpha: 1.0).cgColor // Botanical Sage
        targetFrameView.layer.borderWidth = 2.0
        targetFrameView.layer.cornerRadius = 14
        targetFrameView.backgroundColor = .clear
        view.addSubview(targetFrameView)

        // Clear Cutout in Overlay
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: view.bounds)
        let cutoutPath = UIBezierPath(roundedRect: targetFrameView.frame, cornerRadius: 14)
        path.append(cutoutPath)
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        // Laser Scan Line
        scanLineView.frame = CGRect(x: 10, y: 10, width: boxWidth - 20, height: 2)
        scanLineView.backgroundColor = UIColor(red: 0.494, green: 0.624, blue: 0.522, alpha: 0.9)
        targetFrameView.addSubview(scanLineView)
        animateScanLine()

        // Instruction Label
        instructionLabel.text = "EAN-Barcode im Rahmen positionieren"
        instructionLabel.textColor = UIColor(red: 0.965, green: 0.953, blue: 0.929, alpha: 1.0)
        instructionLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.frame = CGRect(x: 20, y: targetFrameView.frame.maxY + 24, width: view.bounds.width - 40, height: 20)
        view.addSubview(instructionLabel)

        // Close Button
        closeButton.setTitle("Schließen", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        closeButton.backgroundColor = UIColor(white: 0.15, alpha: 0.85)
        closeButton.layer.cornerRadius = 18
        closeButton.frame = CGRect(x: view.bounds.width - 125, y: 54, width: 105, height: 36)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(closeButton)

        // Flashlight / Torch Button
        updateTorchButtonAppearance()
        torchButton.layer.cornerRadius = 18
        torchButton.frame = CGRect(x: 20, y: 54, width: 105, height: 36)
        torchButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        view.addSubview(torchButton)
    }

    private func updateTorchButtonAppearance() {
        let title = isTorchOn ? " Licht An" : " Licht"
        let iconName = isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill"
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let icon = UIImage(systemName: iconName, withConfiguration: config)

        torchButton.setImage(icon, for: .normal)
        torchButton.setTitle(title, for: .normal)
        torchButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        torchButton.backgroundColor = isTorchOn ? UIColor(red: 0.824, green: 0.706, blue: 0.549, alpha: 0.95) : UIColor(white: 0.15, alpha: 0.85)
        torchButton.tintColor = isTorchOn ? .black : .white
        torchButton.setTitleColor(isTorchOn ? .black : .white, for: .normal)
    }

    private func animateScanLine() {
        let maxTravel = targetFrameView.bounds.height - 20
        UIView.animate(withDuration: 1.6, delay: 0, options: [.repeat, .autoreverse, .curveEaseInOut]) { [weak self] in
            self?.scanLineView.transform = CGAffineTransform(translationX: 0, y: maxTravel)
        }
    }

    @objc private func toggleTorch() {
        guard let device = currentDevice ?? AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            isTorchOn.toggle()
            if isTorchOn {
                if device.isTorchModeSupported(.on) {
                    try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                }
            } else {
                if device.isTorchModeSupported(.off) {
                    device.torchMode = .off
                }
            }
            device.unlockForConfiguration()
            updateTorchButtonAppearance()
            HapticFeedbackService.shared.lightDetent()
        } catch {
            print("Torch error: \(error)")
        }
    }

    @objc private func handleClose() {
        if isTorchOn {
            toggleTorch()
        }
        delegate?.didCancel()
    }

    private func showPermissionDenied(message: String = "Kamerazugriff verweigert. Bitte in den iOS-Einstellungen erlauben.") {
        let label = UILabel(frame: CGRect(x: 30, y: (view.bounds.height - 100) / 2, width: view.bounds.width - 60, height: 80))
        label.text = message
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        view.addSubview(label)

        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: (view.bounds.width - 120) / 2, y: label.frame.maxY + 20, width: 120, height: 40)
        btn.setTitle("Schliessen", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        btn.layer.cornerRadius = 10
        btn.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(btn)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
        overlayView.frame = view.bounds

        let boxWidth: CGFloat = min(280, view.bounds.width - 60)
        let boxHeight: CGFloat = 160
        targetFrameView.frame = CGRect(
            x: (view.bounds.width - boxWidth) / 2,
            y: (view.bounds.height - boxHeight) / 2 - 30,
            width: boxWidth,
            height: boxHeight
        )

        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: view.bounds)
        let cutoutPath = UIBezierPath(roundedRect: targetFrameView.frame, cornerRadius: 14)
        path.append(cutoutPath)
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        instructionLabel.frame = CGRect(x: 20, y: targetFrameView.frame.maxY + 24, width: view.bounds.width - 40, height: 20)

        let topY = max(view.safeAreaInsets.top + 8, 48)
        torchButton.frame = CGRect(x: 20, y: topY, width: 105, height: 36)
        closeButton.frame = CGRect(x: view.bounds.width - 125, y: topY, width: 105, height: 36)
        view.bringSubviewToFront(torchButton)
        view.bringSubviewToFront(closeButton)
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasDetected, let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue, !stringValue.isEmpty else { return }

        hasDetected = true
        HapticFeedbackService.shared.commitSuccess()
        if isTorchOn {
            toggleTorch()
        }
        delegate?.didFindCode(stringValue)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isTorchOn {
            toggleTorch()
        }
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }

    deinit {
        if isTorchOn, let device = currentDevice {
            try? device.lockForConfiguration()
            if device.isTorchModeSupported(.off) {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        }
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
}
