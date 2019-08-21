// Adapted from Lona: https://github.com/airbnb/Lona
//
// MIT License
//
// Copyright (c) 2017 Airbnb
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

public class LRUCache<Key: Hashable, Item> {
    var maxEntries: Int
    var data: [Key: Item] = [:]
    var lru: [Key] = []

    init(maxEntries: Int = 100) {
        self.maxEntries = maxEntries
    }

    // MARK: Public

    func add(item: Item, for key: Key) {
        if data[key] == nil {
            push(entry: key)
        } else {
            refresh(entry: key)
        }

        data[key] = item
    }

    func remove(key: Key) {
        data.removeValue(forKey: key)
    }

    func item(for key: Key) -> Item? {
        return data[key]
    }

    // MARK: Private

    private func evict() {
        if lru.count > maxEntries {
            lru.removeLast(lru.count - maxEntries)
        }
    }

    private func push(entry: Key) {
        lru.insert(entry, at: 0)
        evict()
    }

    private func refresh(entry: Key) {
        guard let index = lru.firstIndex(of: entry) else { return }
        lru.remove(at: index)
        lru.insert(entry, at: 0)
    }
}
