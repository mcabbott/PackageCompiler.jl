function verify_gcc(gcc)
    try
        return success(`$gcc --version`)
    catch
        return false
    end
end

if Sys.iswindows()
    using WinRPM
end

function build()
    gccpath = ""
    if isfile("deps.jl")
        include("deps.jl")
        if verify_gcc(gcc)
            @info "GCC already installed and package already built"
            return
        else
            rm("deps.jl")
        end
    end

    if haskey(ENV, "CC")
        if !verify_gcc(`$(ENV["CC"]) -v`)
            error("Using compiler override from environment variable CC = $(ENV["CC"]), but unable to run `$(ENV["CC"]) -v`.")
        end
        gccpath = ENV["CC"]
        @info "Using `$gccpath` as C compiler from environment variable CC"
    end

    @info "Looking for GCC"

    gccargs = ``
    if verify_gcc("cc")
        gccpath = "cc"
        @info "Using `cc` as C compiler"
    elseif Sys.iswindows()
        sysroot = joinpath(WinRPM.installdir, "usr", "$(Sys.ARCH)-w64-mingw32", "sys-root")
        gccpath = joinpath(sysroot, "mingw", "bin", "gcc.exe")
        if !isfile(gccpath)
            @info "Could not find GCC, installing using WinRPM"
            WinRPM.install("gcc", yes = true)
        end
        if !isfile(gccpath)
            error("Couldn't install gcc via WinRPM")
        end
        gccargs = `$gccargs --sysroot $sysroot`
        @info "Using `gcc` from WinRPM as C compiler"
    elseif Sys.isunix() && verify_gcc("gcc")
        gccpath = "gcc"
        @info "Using `gcc` as C compiler"
    end

    if isempty(gccpath)
        error("""
            Please make sure to provide a working gcc in your path!
            You may need to install GCC.
            """
        )
        Sys.isapple() && @info "You can install GCC using Homebrew by `brew install gcc`"
        Sys.islinux() && @info """
                                You can install GCC using `sudo apt-get install gcc` on Debian, 
                                or use your distro's package manager.
                                """
    end
    open("deps.jl", "w") do io
        println(io, "const gcc = ", repr(`$gccpath $gccargs`))
    end
end

build()
