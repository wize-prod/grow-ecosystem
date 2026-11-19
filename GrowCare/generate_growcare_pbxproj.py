#!/usr/bin/env python3
import os

source_files = [
    ("GrowCareApp.swift", "GrowCareApp.swift"),
    ("Models/CustomRecurrenceRule.swift", "CustomRecurrenceRule.swift"),
    ("Models/CareLogModels.swift", "CareLogModels.swift"),
    ("Models/CareModels.swift", "CareModels.swift"),
    ("Models/ChoreModels.swift", "ChoreModels.swift"),
    ("Services/CareNotificationService.swift", "CareNotificationService.swift"),
    ("Services/ChoreNotificationService.swift", "ChoreNotificationService.swift"),
    ("Services/GrowCareStore.swift", "GrowCareStore.swift"),
    ("Services/GrowEcosystemRouter.swift", "GrowEcosystemRouter.swift"),
    ("Services/SharedMacrosBridge.swift", "SharedMacrosBridge.swift"),
    ("Theme/CareTheme.swift", "CareTheme.swift"),
    ("Views/CareCalendarStripView.swift", "CareCalendarStripView.swift"),
    ("Views/CareInventoryView.swift", "CareInventoryView.swift"),
    ("Views/CareLogView.swift", "CareLogView.swift"),
    ("Views/CareProductDetailSheet.swift", "CareProductDetailSheet.swift"),
    ("Views/ChoreDetailSheet.swift", "ChoreDetailSheet.swift"),
    ("Views/MainTabView.swift", "MainTabView.swift"),
    ("Views/RoutineDetailSheet.swift", "RoutineDetailSheet.swift"),
    ("Views/RoutineRunnerSheet.swift", "RoutineRunnerSheet.swift"),
    ("Views/CareZoneSelectorView.swift", "CareZoneSelectorView.swift"),
    ("Views/StandardsGuideView.swift", "StandardsGuideView.swift"),
]

# ID generators
def make_id(prefix, idx):
    return f"{prefix}{idx:022X}"

build_files = []
file_refs = []
sources_entries = []
group_children = []

# Source files
for idx, (rel_path, name) in enumerate(source_files):
    b_id = make_id("BB", idx)
    f_id = make_id("FA", idx)
    build_files.append(f"\t\t{b_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {f_id} /* {name} */; }};")
    file_refs.append(f"\t\t{f_id} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{rel_path}\"; sourceTree = \"<group>\"; }};")
    sources_entries.append(f"\t\t\t\t{b_id} /* {name} in Sources */,")
    group_children.append(f"\t\t\t\t{f_id} /* {name} */,")

# Assets.xcassets
assets_b_id = make_id("BB", 100)
assets_f_id = make_id("FA", 100)
build_files.append(f"\t\t{assets_b_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_f_id} /* Assets.xcassets */; }};")
file_refs.append(f"\t\t{assets_f_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = \"Assets.xcassets\"; sourceTree = \"<group>\"; }};")
group_children.append(f"\t\t\t\t{assets_f_id} /* Assets.xcassets */,")

# Info.plist & entitlements
info_f_id = make_id("FA", 101)
ent_f_id = make_id("FA", 102)
file_refs.append(f"\t\t{info_f_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = \"Info.plist\"; sourceTree = \"<group>\"; }};")
file_refs.append(f"\t\t{ent_f_id} /* GrowCare.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = \"GrowCare.entitlements\"; sourceTree = \"<group>\"; }};")
group_children.append(f"\t\t\t\t{info_f_id} /* Info.plist */,")
group_children.append(f"\t\t\t\t{ent_f_id} /* GrowCare.entitlements */,")

# Product file ref
prod_f_id = make_id("FA", 200)
file_refs.append(f"\t\t{prod_f_id} /* GrowCare.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = GrowCare.app; sourceTree = BUILT_PRODUCTS_DIR; }};")

pbxproj_content = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{os.linesep.join(build_files)}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{os.linesep.join(file_refs)}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		A11111111111111111111111 /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		A22222222222222222222222 /* GrowCare */ = {{
			isa = PBXGroup;
			children = (
{os.linesep.join(group_children)}
			);
			path = GrowCare;
			sourceTree = "<group>";
		}};
		A33333333333333333333333 /* Products */ = {{
			isa = PBXGroup;
			children = (
				{prod_f_id} /* GrowCare.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		A44444444444444444444444 = {{
			isa = PBXGroup;
			children = (
				A22222222222222222222222 /* GrowCare */,
				A33333333333333333333333 /* Products */,
			);
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		A77777777777777777777777 /* GrowCare */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = A55555555555555555555551 /* Build configuration list for PBXNativeTarget "GrowCare" */;
			buildPhases = (
				A66666666666666666666661 /* Sources */,
				A11111111111111111111111 /* Frameworks */,
				A66666666666666666666662 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = GrowCare;
			productName = GrowCare;
			productReference = {prod_f_id} /* GrowCare.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		A88888888888888888888888 /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					A77777777777777777777777 = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = A55555555555555555555552 /* Build configuration list for PBXProject "GrowCare" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = de;
			hasScannedForEncodings = 0;
			knownRegions = (
				de,
				en,
				Base,
			);
			mainGroup = A44444444444444444444444;
			productRefGroup = A33333333333333333333333 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				A77777777777777777777777 /* GrowCare */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		A66666666666666666666662 /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{assets_b_id} /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		A66666666666666666666661 /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{os.linesep.join(sources_entries)}
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		A99999999999999999999991 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		A99999999999999999999992 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		A99999999999999999999993 /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
				CODE_SIGN_ENTITLEMENTS = GrowCare/GrowCare.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = X83D9W2G74;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = GrowCare/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nkembi.growcare;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		A99999999999999999999994 /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES;
				CODE_SIGN_ENTITLEMENTS = GrowCare/GrowCare.entitlements;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = X83D9W2G74;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = GrowCare/Info.plist;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.nkembi.growcare;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		A55555555555555555555551 /* Build configuration list for PBXNativeTarget "GrowCare" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				A99999999999999999999993 /* Debug */,
				A99999999999999999999994 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		A55555555555555555555552 /* Build configuration list for PBXProject "GrowCare" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				A99999999999999999999991 /* Debug */,
				A99999999999999999999992 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */

	}};
	rootObject = A88888888888888888888888 /* Project object */;
}}
"""

out_path = "/Users/parris-campbellnkembi/Developer/GrowWorkspace/GrowCare/GrowCare.xcodeproj/project.pbxproj"
with open(out_path, "w") as f:
    f.write(pbxproj_content)
print(f"Generated {out_path} with {len(source_files)} source files.")
