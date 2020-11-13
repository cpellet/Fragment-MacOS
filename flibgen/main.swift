//
//  main.swift
//  flibgen
//
//  Created by Cyrus Pellet on 24/08/2020.
//

import Foundation

struct ManifestEntry: Encodable, Decodable{
    var libTitle: String
    var libURL: String
    var libAuthor: String
    var checksum: String
    var libDescription: String
    var libFragmentList: [String]
}

func generateManifestFile(entries: [ManifestEntry]){
    let jsonEncoder = JSONEncoder()
    let jsonData = try! jsonEncoder.encode(entries)
    try! jsonData.write(to: FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0].appendingPathComponent("manifest").appendingPathExtension("json"))
}

generateManifestFile(entries: [ManifestEntry(libTitle: "Core", libURL: "https://fragment-161bd.web.app/packages/libraries/Core.flib", libAuthor: "Fragment", checksum: "a93816b0dec9bb11df7159b03635d1a5adc031fae77b6826cd5b1bde93671a54", libDescription: "Includes core methods to issue fragment queries", libFragmentList: ["test"]), ManifestEntry(libTitle: "Calculus", libURL: "https://fragment-161bd.web.app/packages/libraries/Calculus.flib", libAuthor: "Cyrus", checksum: "a8fc1d772e5cad0dee2d997589d4c4c9649006376eaa0c330e310cef0a24425a", libDescription: "Includes common calculus operations", libFragmentList: ["differentiate","integrate","limit"]), ManifestEntry(libTitle: "Algebra", libURL: "https://fragment-161bd.web.app/packages/libraries/Algebra.flib", libAuthor: "Cyrus", checksum: "862fef83b0b2844697df3d9965640d6d8ec9e677fc3cf71a9b38b3bf3a8aa57c", libDescription: "Contains various utilities for dealing with algebraic expressions", libFragmentList: ["expand","factor","simplify","define","linsolve","syslinsolve","syssolve"])])

//generateLibraryFile(lib: FragmentLibrary(title: "Core", remoteURL: "https://fragment-161bd.web.app/packages/libraries/Core.flib", author: "Fragment", description: "Includes core methods to issue fragment queries", updatedDate: Date(), dependencies: [], fragments: [Fragment(title: "test", description: "test fragment", resEvalString: "", dispEvalString: nil, probEvalString: nil, usageTemplate: "test <arg> <args>...")]))

//generateLibraryFile(lib: FragmentLibrary(title: "Calculus", remoteURL: "https://fragment-161bd.web.app/packages/libraries/Calculus.flib", author: "Cyrus", description: "Includes common calculus operations", updatedDate: Date(), dependencies: [Dependency(type: .PythonLib, name: "sympy", minVersion: 1.0, manifestURL: "")], fragments: [Fragment(title: "differentiate", description: "<nth> derivative of <expr> with respect to <var>", resEvalString: "diff(fa[0],fa[1],fa[2]) if len(fa) == 3 else diff(fa[0],fa[1]) if len(fa) == 2 else diff(fa[0])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = \\\"\\\\\\\\frac{\\\\\\\\mathrm{d}}{\\\\\\\\mathrm{d}\\\"+((str(fa[1]) if len(fa) > 1 else \\\"x\\\")+ \\\"^{\\\"+(str(fa[2]) if len(fa) == 3 else \\\"\\\")+\\\"}\\\")+\\\"}\\\"+latex(str(fa[0]))\"", usageTemplate: "differentiate <expr> <(var)> <(nth)>"), Fragment(title: "integrate", description: "integral of <expr> with respect to <var> between <low> and <high>", resEvalString: "integrate(fa[0],(fa[1],fa[2],fa[3])) if len(fa) == 4 else integrate(fa[0],fa[1]) if len(fa) == 2 else integrate(fa[0])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out =\\\"\\\\\\\\int_{\\\"+ (str(fa[2]) if len(fa) > 2 else \\\"\\\")+\\\"}^{\\\"+(str(fa[3]) if len(fa) > 2 else \\\"\\\") +\\\"}\\\"+latex(str(fa[0]))+\\\"\\,d\\\"+(str(fa[1]) if len(fa) > 1 else \\\"x\\\")\"", usageTemplate: "integrate <expr> <(var)> <(low)> <(high)>"), Fragment(title: "limit", description: "limit of <expr> as <var> tends to <val>", resEvalString: "limit(fa[0],fa[1],fa[2])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out =\\\"\\\\\\\\lim_{\\\"+str(fa[1])+\\\"\\\\\\\\to \\\"+str(fa[2]) +\\\"}\\\"+latex(str(fa[0]))\"", usageTemplate: "limit <expr> <var> <val>")], bootstrapCode: "x, y, z = symbols('x y z')"))


//generateLibraryFile(lib: FragmentLibrary(title: "Algebra", remoteURL: "https://fragment-161bd.web.app/packages/libraries/Calculus.flib", author: "Cyrus", description: "Contains various utilities for dealing with algebraic expressions", updatedDate: Date(), dependencies: [Dependency(type: .PythonLib, name: "sympy", minVersion: 1.0, manifestURL: "")], fragments: [Fragment(title: "expand", description: "Expand <expr>", resEvalString: "expand(fa[0])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[0])\"", usageTemplate: "expand <expr>"),Fragment(title: "factor", description: "Factorise <expr>", resEvalString: "factor(fa[0])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[0])\"", usageTemplate: "factor <expr>"),Fragment(title: "simplify", description: "Simplify <expr>", resEvalString: "simplify(fa[0])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[0])\"", usageTemplate: "simplify <expr>"),Fragment(title: "define", description: "Define <var> for use in expressions", resEvalString: "%%A1 = symbols('%%A1');return(\"%%A1\")", dispEvalString: "return (\"%%R\")", probEvalString: "\"f_out =\\\"OK\\\"\"", usageTemplate: "define <var>"),Fragment(title: "linsolve", description: "Solve for <var> in linear expression <expr>", resEvalString: "solve(fa[0],fa[1])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[1])\"", usageTemplate: "linsolve <expr> <var>"),Fragment(title: "syslinsolve", description: "Solve for <var..> in system of linear expressions <expr...>", resEvalString: "linsolve(fa[0],fa[1])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[1])\"", usageTemplate: "syslinsolve <expr...> <var...>"),Fragment(title: "syssolve", description: "Solve for <var..> in system of expressions <expr...>", resEvalString: "nonlinsolve(fa[0],fa[1])", dispEvalString: "latex(%%R)", probEvalString: "\"f_out = latex(fa[1])\"", usageTemplate: "syssolve <expr...> <var...>")], bootstrapCode: "x,y,z,a,b = symbols('x y z a b')"))
