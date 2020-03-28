//
//  Memoize.swift
//  Logic
//
//  Created by Devin Abbott on 7/27/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import Foundation

// MARK: - Memoize

public enum Memoize {

    // MARK: Memoize one

    public static func one<I, O>(_ f: @escaping (I) -> O) -> (I) -> O where I: Equatable {
        var memo: (input: I, output: O)?

        return { input in
            if let memo = memo, memo.input == input {
                return memo.output
            }

            let output = f(input)

            memo = (input, output)

            return output
        }
    }

    public static func one<I1, I2, O>(_ f: @escaping (I1, I2) -> O) -> (I1, I2) -> O where I1: Equatable, I2: Equatable {
        var memo: (input1: I1, input2: I2, output: O)?

        return { input1, input2 in
            if let memo = memo, memo.input1 == input1, memo.input2 == input2 {
                return memo.output
            }

            let output = f(input1, input2)

            memo = (input1, input2, output)

            return output
        }
    }

    public static func one<I1, I2, I3, O>(_ f: @escaping (I1, I2, I3) -> O) -> (I1, I2, I3) -> O where I1: Equatable, I2: Equatable, I3: Equatable {
        var memo: (input1: I1, input2: I2, input3: I3, output: O)?

        return { input1, input2, input3 in
            if let memo = memo, memo.input1 == input1, memo.input2 == input2, memo.input3 == input3 {
                return memo.output
            }

            let output = f(input1, input2, input3)

            memo = (input1, input2, input3, output)

            return output
        }
    }

    public static func one<I1, I2, I3, I4, O>(_ f: @escaping (I1, I2, I3, I4) -> O) -> (I1, I2, I3, I4) -> O
        where I1: Equatable, I2: Equatable, I3: Equatable, I4: Equatable {
            var memo: (input1: I1, input2: I2, input3: I3, input4: I4, output: O)?

            return { input1, input2, input3, input4 in
                if let memo = memo,
                    memo.input1 == input1,
                    memo.input2 == input2,
                    memo.input3 == input3,
                    memo.input4 == input4 {
                    return memo.output
                }

                let output = f(input1, input2, input3, input4)

                memo = (input1, input2, input3, input4, output)

                return output
            }
    }

    public static func one<I1, I2, I3, I4, I5, O>(_ f: @escaping (I1, I2, I3, I4, I5) -> O) -> (I1, I2, I3, I4, I5) -> O
        where I1: Equatable, I2: Equatable, I3: Equatable, I4: Equatable, I5: Equatable {
            var memo: (input1: I1, input2: I2, input3: I3, input4: I4, input5: I5, output: O)?

            return { input1, input2, input3, input4, input5 in
                if let memo = memo,
                    memo.input1 == input1,
                    memo.input2 == input2,
                    memo.input3 == input3,
                    memo.input4 == input4,
                    memo.input5 == input5 {
                    return memo.output
                }

                let output = f(input1, input2, input3, input4, input5)

                memo = (input1, input2, input3, input4, input5, output)

                return output
            }
    }

    // MARK: Memoize all

    public static func all<I, O>(_ f: @escaping (I) -> O) -> (I) -> O where I: Hashable {
        var memo: [I: O] = [:]

        return { input in
            if let existing = memo[input] {
                return existing
            }

            let output = f(input)

            memo[input] = output

            return output
        }
    }

    public static func all<I1, I2, O>(_ f: @escaping (I1, I2) -> O) -> (I1, I2) -> O where I1: Hashable, I2: Hashable {
        var memo: [Int: O] = [:]

        return { input1, input2 in
            var hasher = Hasher()
            hasher.combine(input1)
            hasher.combine(input2)
            let hash = hasher.finalize()

            if let existing = memo[hash] {
                return existing
            }

            let output = f(input1, input2)

            memo[hash] = output

            return output
        }
    }

    public static func all<I1, I2, I3, O>(_ f: @escaping (I1, I2, I3) -> O) -> (I1, I2, I3) -> O where I1: Hashable, I2: Hashable, I3: Hashable {
        var memo: [Int: O] = [:]

        return { input1, input2, input3 in
            var hasher = Hasher()
            hasher.combine(input1)
            hasher.combine(input2)
            hasher.combine(input3)
            let hash = hasher.finalize()

            if let existing = memo[hash] {
                return existing
            }

            let output = f(input1, input2, input3)

            memo[hash] = output

            return output
        }
    }

    public static func all<I1, I2, I3, I4, O>(_ f: @escaping (I1, I2, I3, I4) -> O) -> (I1, I2, I3, I4) -> O
        where I1: Hashable, I2: Hashable, I3: Hashable, I4: Hashable {
            var memo: [Int: O] = [:]

            return { input1, input2, input3, input4 in
                var hasher = Hasher()
                hasher.combine(input1)
                hasher.combine(input2)
                hasher.combine(input3)
                hasher.combine(input4)
                let hash = hasher.finalize()

                if let existing = memo[hash] {
                    return existing
                }

                let output = f(input1, input2, input3, input4)

                memo[hash] = output

                return output
            }
    }

    public static func all<I1, I2, I3, I4, I5, O>(_ f: @escaping (I1, I2, I3, I4, I5) -> O) -> (I1, I2, I3, I4, I5) -> O
        where I1: Hashable, I2: Hashable, I3: Hashable, I4: Hashable, I5: Hashable {
            var memo: [Int: O] = [:]

            return { input1, input2, input3, input4, input5 in
                var hasher = Hasher()
                hasher.combine(input1)
                hasher.combine(input2)
                hasher.combine(input3)
                hasher.combine(input4)
                hasher.combine(input5)
                let hash = hasher.finalize()

                if let existing = memo[hash] {
                    return existing
                }

                let output = f(input1, input2, input3, input4, input5)

                memo[hash] = output

                return output
            }
    }
}
