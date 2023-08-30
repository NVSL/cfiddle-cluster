from cfiddle import *
import cfiddle
import delegate_function
from hungwei import HungWeiExecutionMethod

def test_test():
    pass

def test_smoke():
    b = build(code(r"""
#include <iostream>

extern "C"
void hello() {
    std::cout << "hello\n";
}
"""))
    r = run(b, "hello")


def  foo():
    return HungWeiExecutionMethod("/home/tmp", "/usr/local/bin/delegate-function-run")

def test_delegate_function():
    with cfiddle_config(RunnerExecutionMethod_type=foo):
        b = build(code(r"""
#include <iostream>

extern "C"
void hello() {
    std::cout << "hello\n";
}
"""))
        r = run(b, "hello")

        
