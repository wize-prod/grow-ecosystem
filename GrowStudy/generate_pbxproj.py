import os
import uuid

script_dir = os.path.dirname(os.path.abspath(__file__))
growstudy_dir = os.path.join(script_dir, "GrowStudy")

source_files = []
for root, dirs, files in os.walk(growstudy_dir):
    for f in sorted(files):
        if f.endswith(".swift"):
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, growstudy_dir)
            source_files.append(rel_path)
source_files.sort()

resource_files = [
    "Info.plist",
    "GrowStudy.entitlements",
    "Assets.xcassets"
]

build_file_entries = []
file_ref_entries = []
source_build_refs = []
resource_build_refs = []
group_children = []

for idx, sf in enumerate(source_files):
    file_id = f"CA{idx:022X}"
    build_id = f"CB{idx:022X}"
    filename = os.path.basename(sf)
    
    file_ref_entries.append(f'\t\t{file_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{sf}"; sourceTree = "<group>"; }};')
    build_file_entries.append(f'\t\t{build_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {filename} */; }};')
    source_build_refs.append(f'\t\t\t\t{build_id} /* {filename} in Sources */,')
    group_children.append(f'\t\t\t\t{file_id} /* {filename} */,')

for idx, rf in enumerate(resource_files):
    actual_idx = len(source_files) + idx
    file_id = f"CA{actual_idx:022X}"
    build_id = f"CB{actual_idx:022X}"
    filename = os.path.basename(rf)
    
    file_type = "folder.assetcatalog" if "xcassets" in rf else ("text.plist.xml" if "plist" in rf else "text.plist.entitlements")
    file_ref_entries.append(f'\t\t{file_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {file_type}; path = "{rf}"; sourceTree = "<group>"; }};')
    if "xcassets" in rf:
        build_file_entries.append(f'\t\t{build_id} /* {filename} in Resources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {filename} */; }};')
        resource_build_refs.append(f'\t\t\t\t{build_id} /* {filename} in Resources */,')
    group_children.append(f'\t\t\t\t{file_id} /* {filename} */,')

app_product_id = "333333333333333333333333"
app_product_ref = f'\t\t{app_product_id} /* GrowStudy.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GrowStudy.app; sourceTree = BUILT_PRODUCTS_DIR; }};'

pbxproj_content = f"""// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{
\t}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{chr(10).join(build_file_entries)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{app_product_ref}
{chr(10).join(file_ref_entries)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\tA22222222222222222222221 /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
\t\tA33333333333333333333331 /* GrowStudy */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{chr(10).join(group_children)}
\t\t\t);
\t\t\tpath = GrowStudy;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\tA33333333333333333333332 /* Products */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{app_product_id} /* GrowStudy.app */,
\t\t\t);
\t\t\tname = Products;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\tA33333333333333333333333 /* Main */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\tA33333333333333333333331 /* GrowStudy */,
\t\t\t\tA33333333333333333333332 /* Products */,
\t\t\t);
\t\t\tsourceTree = "<group>";
\t\t}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\tA44444444444444444444441 /* GrowStudy */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = A55555555555555555555551 /* Build configuration list for PBXNativeTarget "GrowStudy" */;
\t\t\tbuildPhases = (
\t\t\t\tA66666666666666666666661 /* Sources */,
\t\t\t\tA22222222222222222222221 /* Frameworks */,
\t\t\t\tA77777777777777777777771 /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = GrowStudy;
\t\t\tproductName = GrowStudy;
\t\t\tproductReference = {app_product_id} /* GrowStudy.app */;
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\tA88888888888888888888888 /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tBuildIndependentTargetsInParallel = 1;
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\tA44444444444444444444441 = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t\tDevelopmentTeam = X83D9W2G74;
\t\t\t\t\t\tProvisioningStyle = Automatic;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = A55555555555555555555552 /* Build configuration list for PBXProject "GrowStudy" */;
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = de;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (
\t\t\t\ten,
\t\t\t\tde,
\t\t\t\tBase,
\t\t\t);
\t\t\tmainGroup = A33333333333333333333333 /* Main */;
\t\t\tproductRefGroup = A33333333333333333333332 /* Products */;
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = (
\t\t\t\tA44444444444444444444441 /* GrowStudy */,
\t\t\t);
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\tA77777777777777777777771 /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(resource_build_refs)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\tA66666666666666666666661 /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{chr(10).join(source_build_refs)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\tA99999999999999999999991 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tGCC_PREPROCESSOR_DEFINITIONS = (
\t\t\t\t\t"DEBUG=1",
\t\t\t\t\t"$(inherited)",
\t\t\t\t);
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\tA99999999999999999999992 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_NO_COMMON_BLOCKS = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
\t\tA99999999999999999999993 /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = GrowStudy/GrowStudy.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = X83D9W2G74;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = GrowStudy/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nkembi.growstudy;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2,6";
\t\t\t\tSUPPORTS_MACCATALYST = YES;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\tA99999999999999999999994 /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = GrowStudy/GrowStudy.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = X83D9W2G74;
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = GrowStudy/Info.plist;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.nkembi.growstudy;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2,6";
\t\t\t\tSUPPORTS_MACCATALYST = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\tA55555555555555555555551 /* Build configuration list for PBXNativeTarget "GrowStudy" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tA99999999999999999999993 /* Debug */,
\t\t\t\tA99999999999999999999994 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\tA55555555555555555555552 /* Build configuration list for PBXProject "GrowStudy" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\tA99999999999999999999991 /* Debug */,
\t\t\t\tA99999999999999999999992 /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = A88888888888888888888888 /* Project object */;
}}
"""

out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "GrowStudy.xcodeproj")
os.makedirs(out_dir, exist_ok=True)
with open(os.path.join(out_dir, "project.pbxproj"), "w") as f:
    f.write(pbxproj_content)

print("GrowStudy project.pbxproj generated successfully!")
