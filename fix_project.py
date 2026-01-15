#!/usr/bin/env python3
import hashlib

def gen_id(name):
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()

# File mappings
file_ids = {
    'App/SecondApp.swift': 'B86B2090D8CBCA4326F5C2EE',
    'Models/TOTPParameters.swift': '11944E03D0B4E86F4E3E14D0',
    'Models/Token.swift': '244BB8BC7225CE230E12CA3B',
    'Models/Vault.swift': 'C1E92F7968EE1130CD24BD44',
    'Services/Base32Decoder.swift': '75A787A05A1F132909C44FE0',
    'Services/EncryptionService.swift': '13A40049DD011F015961807E',
    'Services/KeychainService.swift': '203AACB57C64E4B8E9A9586D',
    'Services/QRCodeParser.swift': '31F58991D20260A5B1605644',
    'Services/TOTPGenerator.swift': '9A5A662C9A38DADA76F30777',
    'Services/iCloudSyncService.swift': '0813CC69C091EC9C0653C5A6',
    'Utilities/ClipboardHelper.swift': '4936E43F3D48A698CAF60B30',
    'Utilities/Logger.swift': 'A666D2ABD7BCFF9C951EC822',
    'ViewModels/AddTokenViewModel.swift': '40426F9170AE1434A6E3CEE7',
    'ViewModels/TokenListViewModel.swift': 'DD819725D4BFB33FD7902CC1',
    'Views/AddTokenView.swift': '9B527B8E353DBA4FF2F9BF6A',
    'Views/Components/CountdownTimerView.swift': 'CE4F035DCB34DB562179773E',
    'Views/Components/EmptyStateView.swift': '3A1ACCFD1D35E969D9BF2EBF',
    'Views/Components/QRCodeScannerView.swift': 'AAFAF5CAF0989B53BCB6CF3C',
    'Views/Components/TokenCardView.swift': '96AC43EF7FC06D3591D7ECB9',
    'Views/TokenListView.swift': '0E0CE077688B9E318A96277D',
}

build_ids = {
    'App/SecondApp.swift': 'B01445E502E99D068EF6FC55',
    'Models/TOTPParameters.swift': '8469B68448E5BD04132C8E56',
    'Models/Token.swift': '0133373E1108B3B8094EB3A1',
    'Models/Vault.swift': 'F726D8963D1BC30063D52F1E',
    'Services/Base32Decoder.swift': 'F1489F24C0F4C8EFE1ADD0A2',
    'Services/EncryptionService.swift': '79A30FD93373F1F72BEE403B',
    'Services/KeychainService.swift': '727D9539B3F7D2320C450F7A',
    'Services/QRCodeParser.swift': '658DC41106BC532DC8532A1E',
    'Services/TOTPGenerator.swift': '11578ACA709D9E6AB51F7902',
    'Services/iCloudSyncService.swift': '2E905113B15BCF2B016890E1',
    'Utilities/ClipboardHelper.swift': '2B661077FAFAE287896C051C',
    'Utilities/Logger.swift': 'E56111A740A9613DA98F739D',
    'ViewModels/AddTokenViewModel.swift': '67E06CB5ADB3CFFA5D33ACE1',
    'ViewModels/TokenListViewModel.swift': 'A23131F24D7A02F7046ACF2D',
    'Views/AddTokenView.swift': 'D22DB293CE97CAFB82CB0841',
    'Views/Components/CountdownTimerView.swift': '93C465422DD2B4D01D451E78',
    'Views/Components/EmptyStateView.swift': '0D8BB736C8F936BB2145F390',
    'Views/Components/QRCodeScannerView.swift': '532D2F01F2A69BF5CCFCBB2C',
    'Views/Components/TokenCardView.swift': '536591CE0C1794C044E513FC',
    'Views/TokenListView.swift': 'E356BE4514563A7B18615FB7',
}

# Other IDs
ids = {
    'app': gen_id('Second.app'),
    'info_plist': gen_id('Info.plist'),
    'entitlements': gen_id('Second.entitlements'),
    'frameworks_phase': gen_id('Frameworks'),
    'sources_phase': gen_id('Sources'),
    'resources_phase': gen_id('Resources'),
    'target': gen_id('Second_target'),
    'project': gen_id('Project'),
    'group_root': gen_id('group_root'),
    'group_products': gen_id('group_products'),
    'group_second': gen_id('group_second'),
    'group_app': gen_id('group_app'),
    'group_models': gen_id('group_models'),
    'group_services': gen_id('group_services'),
    'group_utilities': gen_id('group_utilities'),
    'group_viewmodels': gen_id('group_viewmodels'),
    'group_views': gen_id('group_views'),
    'group_components': gen_id('group_components'),
    'group_resources': gen_id('group_resources'),
    'config_debug': gen_id('config_debug'),
    'config_release': gen_id('config_release'),
    'config_list_project': gen_id('config_list_project'),
    'config_list_target': gen_id('config_list_target'),
}

# Build the complete project.pbxproj content
content = """// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
"""

# Add all build files
for path in sorted(build_ids.keys()):
    bid = build_ids[path]
    fid = file_ids[path]
    name = path.split('/')[-1]
    content += f"\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};\n"

content += """/* End PBXBuildFile section */

/* Begin PBXFileReference section */
"""

# Add app and config files
content += f"\t\t{ids['app']} /* Second.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Second.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n"
content += f"\t\t{ids['info_plist']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};\n"
content += f"\t\t{ids['entitlements']} /* Second.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = Second.entitlements; sourceTree = \"<group>\"; }};\n"

# Add all Swift files
for path in sorted(file_ids.keys()):
    fid = file_ids[path]
    name = path.split('/')[-1]
    content += f"\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"

content += f"""/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{ids['frameworks_phase']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{ids['group_root']} = {{
			isa = PBXGroup;
			children = (
				{ids['group_second']} /* Second */,
				{ids['group_products']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{ids['group_products']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{ids['app']} /* Second.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{ids['group_second']} /* Second */ = {{
			isa = PBXGroup;
			children = (
				{ids['group_app']} /* App */,
				{ids['group_models']} /* Models */,
				{ids['group_services']} /* Services */,
				{ids['group_utilities']} /* Utilities */,
				{ids['group_viewmodels']} /* ViewModels */,
				{ids['group_views']} /* Views */,
				{ids['group_resources']} /* Resources */,
				{ids['info_plist']} /* Info.plist */,
				{ids['entitlements']} /* Second.entitlements */,
			);
			path = Second;
			sourceTree = "<group>";
		}};
		{ids['group_app']} /* App */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['App/SecondApp.swift']} /* SecondApp.swift */,
			);
			path = App;
			sourceTree = "<group>";
		}};
		{ids['group_models']} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['Models/Token.swift']} /* Token.swift */,
				{file_ids['Models/TOTPParameters.swift']} /* TOTPParameters.swift */,
				{file_ids['Models/Vault.swift']} /* Vault.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{ids['group_services']} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['Services/Base32Decoder.swift']} /* Base32Decoder.swift */,
				{file_ids['Services/EncryptionService.swift']} /* EncryptionService.swift */,
				{file_ids['Services/iCloudSyncService.swift']} /* iCloudSyncService.swift */,
				{file_ids['Services/KeychainService.swift']} /* KeychainService.swift */,
				{file_ids['Services/QRCodeParser.swift']} /* QRCodeParser.swift */,
				{file_ids['Services/TOTPGenerator.swift']} /* TOTPGenerator.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{ids['group_utilities']} /* Utilities */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['Utilities/ClipboardHelper.swift']} /* ClipboardHelper.swift */,
				{file_ids['Utilities/Logger.swift']} /* Logger.swift */,
			);
			path = Utilities;
			sourceTree = "<group>";
		}};
		{ids['group_viewmodels']} /* ViewModels */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['ViewModels/AddTokenViewModel.swift']} /* AddTokenViewModel.swift */,
				{file_ids['ViewModels/TokenListViewModel.swift']} /* TokenListViewModel.swift */,
			);
			path = ViewModels;
			sourceTree = "<group>";
		}};
		{ids['group_views']} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{ids['group_components']} /* Components */,
				{file_ids['Views/AddTokenView.swift']} /* AddTokenView.swift */,
				{file_ids['Views/TokenListView.swift']} /* TokenListView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{ids['group_components']} /* Components */ = {{
			isa = PBXGroup;
			children = (
				{file_ids['Views/Components/CountdownTimerView.swift']} /* CountdownTimerView.swift */,
				{file_ids['Views/Components/EmptyStateView.swift']} /* EmptyStateView.swift */,
				{file_ids['Views/Components/QRCodeScannerView.swift']} /* QRCodeScannerView.swift */,
				{file_ids['Views/Components/TokenCardView.swift']} /* TokenCardView.swift */,
			);
			path = Components;
			sourceTree = "<group>";
		}};
		{ids['group_resources']} /* Resources */ = {{
			isa = PBXGroup;
			children = (
			);
			path = Resources;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{ids['target']} /* Second */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['config_list_target']} /* Build configuration list for PBXNativeTarget "Second" */;
			buildPhases = (
				{ids['sources_phase']} /* Sources */,
				{ids['frameworks_phase']} /* Frameworks */,
				{ids['resources_phase']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = Second;
			productName = Second;
			productReference = {ids['app']} /* Second.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{ids['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{ids['target']} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {ids['config_list_project']} /* Build configuration list for PBXProject "Second" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {ids['group_root']};
			productRefGroup = {ids['group_products']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{ids['target']} /* Second */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{ids['resources_phase']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{ids['sources_phase']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
"""

# Add all build file references to Sources phase
for path in sorted(build_ids.keys()):
    bid = build_ids[path]
    name = path.split('/')[-1]
    content += f"\t\t\t\t{bid} /* {name} in Sources */,\n"

content += f"""\t\t\t);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{ids['config_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				CODE_SIGN_ENTITLEMENTS = Second/Second.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				INFOPLIST_FILE = Second/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.second.totp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = "1,2";
			}};
			name = Debug;
		}};
		{ids['config_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				CODE_SIGN_ENTITLEMENTS = Second/Second.entitlements;
				CODE_SIGN_STYLE = Automatic;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_C_LANGUAGE_STANDARD = gnu11;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				INFOPLIST_FILE = Second/Info.plist;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				PRODUCT_BUNDLE_IDENTIFIER = com.second.totp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = "1,2";
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{ids['config_list_project']} /* Build configuration list for PBXProject "Second" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['config_debug']} /* Debug */,
				{ids['config_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['config_list_target']} /* Build configuration list for PBXNativeTarget "Second" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['config_debug']} /* Debug */,
				{ids['config_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {ids['project']} /* Project object */;
}}
"""

# Write to file
with open('Second.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ Generated new project.pbxproj with all 20 Swift files")
print("You can now open Second.xcodeproj in Xcode and run the app!")
