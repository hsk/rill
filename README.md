# Rill Programming Language
**experimental...**
![chi-](http://yutopp.net/image/chi-.png "Bun")
[![Build Status](https://travis-ci.org/yutopp/rill.svg?branch=m@ster)](https://travis-ci.org/yutopp/rill)

Rill is a programming language for java sparrow.

This repository contains the implementation of Rill language.

文鳥の文鳥による文鳥のためのプログラミング言語 Rill の処理系です

ブン！ (◔⊖◔) < "ひとまず動くようになるまでゴリ押しで書くのでコードは汚いゾ"


## How to build
### Requirement
#### Compiler
- GCC >= 4.8.0
- Clang >= 3.3

#### Libraries
- Boost 1.55.0
- LLVM 3.4

If you are Ubuntu/Mint user, these links will be useful...
- [boost-latest](https://launchpad.net/~boost-latest/+archive/ppa "boost-latest")
- [LLVM Debian/Ubuntu nightly packages](http://llvm.org/apt/ "LLVM Debian/Ubuntu nightly packages")


### Build and install
For example,
```
git clone git@github.com:yutopp/rill.git
cd rill
mkdir build
cd build
cmake ../.
make
# make test
sudo make install
```
Rill specific variables for CMake

|Name|Description|Default|
|:--|:--|:--|
|LLVM_CONFIG_PATH | location path of `llvm-config` | `/usr/bin/llvm-config` |
|BOOST_ROOT| location path of boost libraries | *auto* |
|RUN_TEST| set `ON` if you would like to run tests | OFF |
Please change these variables to fit your environment.
e.g.
```
cmake ../. -DLLVM_CONFIG_PATH=/usr/bin/llvm-config-3.4 -DRUN_TEST=ON
```

After that, execute `make`, (`make test`),  and `sudo make install`.


#### Other configuration
You can specify paths that dependent libraries are installed by using `CMAKE_PREFIX_PATH` . e.g.

```
cmake ../. -DCMAKE_PREFIX_PATH=/usr/local
```

And, you can specify the path that Rill will be installed by using `CMAKE_INSTALL_PREFIX` . e.g.

```
cmake ../. -DCMAKE_INSTALL_PREFIX=/usr/local/torigoya
```

If you want to use Clang, call CMake like below.

```
cmake ../. -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang
```

## Test
```
cd build
cmake test
```

### Auto testing
At first time,
```
bundle install --path vendor/bundle
```

After that, execute below
```
cd build
bundle exec guard -i -G ../Guardfile -w ../
```


## How to use
e.g. (on the directory of rill)
```
rillc tools/compiler/samples/...
```
and then, executable file `a.out` will be generated.

To see detail, execute `rillc --help`.


## Reference

under construction


## Sample Code of Rill

```
def main(): int
{
    print( "hello, bunchou lang!!!" );
    test();

    return 0;
}

def test(): void
{
    extern_print_string( foo( ( 10*2 )*(1+2*2   ), 10 ) + 2 * 5 );
}

extern def extern_print_string( :int ): void "put_string2";


def foo( fuga: int, hoge: int ): int
{
    return foo(fuga) * hoge;
}

def foo( a: int ): int
{
    return a;
}

// comment
;/*empty statment*/;;;
```


## License

Boost License Version 1.0
