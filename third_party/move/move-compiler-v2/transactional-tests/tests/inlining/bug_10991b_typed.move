//# publish
module 0x42::Test {
    inline fun foo(g: |u64, u64| u64, x: u64, _y: u64): u64 {
        g(x, _y)
    }

    public fun test() {
        assert!(foo(|_: u64, y: u64| y,
	    10, 100) == 100, 0);
    }
}

//# run 0x42::Test::test
