// swift-tools-version: 5.7

enum PackageModule {
    case `internal`(Internal)
    case external(External)
    
    enum Internal: CaseIterable {
        case networking
        
        var module: Module {
            switch self {
            case .networking:
                Module(
                    name: "Networking",
                    dependencies: [
                        .external(.swiftHTTPType),
                        .external(.utilities)
                    ],
                    productType: .library(hasResources: false),
                    testsOption: .enabled(hasResourses: false)
                )
            }
        }
    }
    
    enum External: CaseIterable {
        case swiftHTTPType
        case utilities
        
        var module: Module {
            switch self {
            case .swiftHTTPType:
                Module(
                    name: "HTTPTypes",
                    packageInfo: .init(
                        name: "swift-http-types",
                        url: "https://github.com/apple/swift-http-types.git",
                        version: .tag(.from("1.4.0"))
                    )
                )
            case .utilities:
                Module(
                    name: "Utilities",
                    packageInfo: .init(
                        name: "swift-utilities",
                        url: "https://github.com/nicklu717/swift-utilities.git",
                        version: .tag(.from("1.2.0"))
                    )
                )
            }
        }
    }
}

// MARK: - Module Definitions
extension PackageModule.Internal {
    class Module {
        enum ProductType {
            case library(hasResources: Bool)
            case executable
        }
        
        enum TestsOption {
            case enabled(hasResourses: Bool)
            case disabled
        }
        
        let name: String
        let dependencies: [PackageModule]
        let path: String
        let productType: ProductType
        let testsOption: TestsOption
        
        init(name: String, dependencies: [PackageModule], intermediateDirectoryPath: String = "", productType: ProductType, testsOption: TestsOption) {
            self.name = name
            self.dependencies = dependencies
            self.path = "\(intermediateDirectoryPath)\(name)/"
            self.productType = productType
            self.testsOption = testsOption
        }
    }
}

extension PackageModule.External {
    class Module {
        struct PackageInfo {
            let name: String
            let url: String
            let version: Version
            
            enum Version {
                case tag(Tag)
                case branch(String)
                
                enum Tag {
                    case from(String)
                    case exact(String)
                }
            }
        }
        
        let name: String
        let packageInfo: PackageInfo
        
        init(name: String, packageInfo: PackageInfo) {
            self.name = name
            self.packageInfo = packageInfo
        }
    }
}

// MARK: - Generate Package
import PackageDescription

extension PackageModule.Internal.Module {
    var product: Product {
        switch productType {
        case .library:
            return .library(name: name, targets: [name])
        case .executable:
            return .executable(name: name, targets: [name])
        }
    }
    
    var target: Target {
        let dependencies: [Target.Dependency] = dependencies.map { dependency in
            switch dependency {
            case .internal(let `internal`):
                return .byName(name: `internal`.module.name)
            case .external(let external):
                return external.module.product
            }
        }
        let path = "Sources/\(path)"
        switch productType {
        case .library(let hasResources):
            let resources: [Resource]? = hasResources ? [.process("Resources")] : nil
            return .target(name: name, dependencies: dependencies, path: path, resources: resources)
        case .executable:
            return .executableTarget(name: name, dependencies: dependencies, path: path)
        }
    }
    
    var testTarget: Target? {
        switch testsOption {
        case .enabled(let hasResourses):
            return .testTarget(
                name: "\(name)Tests",
                dependencies: [.byName(name: name)],
                path: "Tests/\(path)",
                resources: hasResourses ? [.process("Resources")] : nil
            )
        case .disabled:
            return nil
        }
    }
}

extension PackageModule.External.Module {
    var package: Package.Dependency {
        switch packageInfo.version {
        case .tag(let tag):
            switch tag {
            case .from(let version):
                return .package(url: packageInfo.url, from: Version(stringLiteral: version))
            case .exact(let version):
                return .package(url: packageInfo.url, exact: Version(stringLiteral: version))
            }
        case .branch(let branch):
            return .package(url: packageInfo.url, branch: branch)
        }
    }
    
    var product: Target.Dependency {
        .product(name: name, package: packageInfo.name)
    }
}

let internalModules = PackageModule.Internal.allCases.map(\.module)
let externalModules = PackageModule.External.allCases.map(\.module)

let package = Package(
    name: "swift-networking",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: internalModules.map(\.product),
    dependencies: externalModules.map(\.package),
    targets: internalModules.map(\.target) + internalModules.compactMap(\.testTarget)
)
