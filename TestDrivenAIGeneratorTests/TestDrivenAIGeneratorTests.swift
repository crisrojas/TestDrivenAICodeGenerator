//
//  TestDrivenAIGeneratorTests.swift
//  TestDrivenAIGeneratorTests
//
//  Created by Cristian Felipe Patiño Rojas on 13/12/24.
//

import Testing
@testable import TestDrivenAIGenerator

struct Generator {
    let client: Client
    let runner: Runner
    
    struct Result {
        let generatedCode: String
        let specifications: String
        let compliesSpecifications: Bool
    }
    
    func generateCode(from specs: String, iterationLimit: Int = 5, iterationCallback: (Int) -> Void) async -> Result {
        var generated = await client.send(specs: specs)
        var output    = runner.run(generated)
        var result: Result {
            Result(
                generatedCode: generated,
                specifications: specs,
                compliesSpecifications: output.isEmpty
            )
        }
        
        var currentIteration = 0 {
            didSet {
                iterationCallback(currentIteration)
            }
        }
        
        while currentIteration < iterationLimit {
            currentIteration += 1
            generated = await client.send(specs: specs)
            output = runner.run(generated)
            if result.compliesSpecifications {
                break
            }
        }
        
        return result
    }
}

extension Generator {
    protocol Client {
        func send(specs: String) async -> String
    }
    
    protocol Runner {
        func run(_ code: String) -> String
    }
}


struct TestDrivenAIGeneratorTests {

    struct MockClient: Generator.Client {
        func send(specs: String) async -> String {""}
    }
    
    @Test func test_generator_delivers_success_output() async throws {
        struct MockRunner: Generator.Runner {
            func run(_ code: String) -> String {""}
        }
 
        let sut = Generator(client: MockClient(), runner: MockRunner())
        let anySpecs = anySpecs()
        
        let result = await sut.generateCode(from: anySpecs, iterationCallback: {_ in})
        
        #expect(result.compliesSpecifications)
    }
    
    @Test func test_generator_delivers_success_output_after_N_iterations() async throws {
        
        final class MockRunner: Generator.Runner {
            let successOnIteration: Int
            var currentIteration = 0
            init(successOnIteration: Int) {
                self.successOnIteration = successOnIteration
            }
            
            func run(_ code: String) -> String {
               let output = successOnIteration == currentIteration
                ? ""
                : "failure"
                
                currentIteration += 1
                return output
            }
        }
        
        let runner = MockRunner(successOnIteration: 3)
        
        let sut = Generator(client: MockClient(), runner: runner)
        let anySpecs = anySpecs()
        
        var expectedIterations = [Int]()
        let result = await sut.generateCode(from: anySpecs, iterationLimit: 3, iterationCallback: {
            expectedIterations.append($0)
        })
        
        #expect(result.compliesSpecifications)
        #expect(expectedIterations == [1,2,3])
    }
    
    func anySpecs() -> String {
    """
    func test_adder() {
        let sut = Adder(1,2)
        assert(sut.result == 3)
    }
    """
    }
    
}
