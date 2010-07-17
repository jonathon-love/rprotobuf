#!/usr/bin/r -t


basicUse <- function(verbose=TRUE) {
    readProtoFiles("TradeData.proto")
    x <- read( TradeData.Trades, "trades.pb")
    xl <- as.list(x)
    df <- do.call(rbind, lapply(as.list(xl$fill), function(.) as.data.frame(as.list(.))))
    df[,1] <- as.POSIXct(df[,1], origin="1970-01-01")
    if (verbose) print(summary(df))
    invisible(NULL)
}

timedUse <- function() {
    a1 <- system.time(readProtoFiles("TradeData.proto"))
    a2 <- system.time(x <- read( TradeData.Trades, "trades.pb"))
    a3 <- system.time(xl <- as.list(x))
    a4 <- system.time(df <- do.call(rbind, lapply(as.list(xl$fill), function(.) as.data.frame(as.list(.)))))
    print(summary(df))

    print(rbind(a1, a2, a3, a4))
    invisible(NULL)
}

profiledUse <- function() {
    Rprof(filename = "loadIt-Rprof.out", interval = 0.01)
    readProtoFiles("TradeData.proto")
    x <- read( TradeData.Trades, "trades.pb")
    xl <- as.list(x)
    df <- do.call(rbind, lapply(as.list(xl$fill), function(.) as.data.frame(as.list(.))))
    print(summary(df))
    Rprof(NULL)
    invisible(NULL)
}


preAlloc <- function(verbose=TRUE) {
    readProtoFiles("TradeData.proto")
    x <- read( TradeData.Trades, "trades.pb")
    x1 <- as.list(x)									# 36 sec
    xl <- as.list(x1$fill)
    n <- length(xl)
    df <- data.frame(ts    = rep(NA, n),
                     sym   = rep("", n),
                     price = rep(NA, n),
                     size  = rep(NA, n),
                     stringsAsFactors=FALSE)
    for (i in 1:n) {
         df[i, ] <- as.list(xl[[i]])
    }
    df[,1] <- as.POSIXct(df[,1], origin="1970-01-01")
    if (verbose) print(summary(df))
    invisible(NULL)
}

compiled <- function(verbose=FALSE, file="trades.pb") {
    suppressMessages(library(utils))
    suppressMessages(library(Rcpp))

    stopifnot(file.exists(file))

    df <- .Call("pbload", file);

    if (verbose) print(summary(df))

    invisible(NULL)
}

moduled <- function(file="trades.pb") {
    suppressMessages(library(utils))
    suppressMessages(library(Rcpp))

    stopifnot(file.exists(file))
    dyn.load("trade.mod.so")

    yada <- new("Module")
    NAMESPACE <- environment()
    unlockBinding("yada", NAMESPACE)
    assign("yada", Module("yada"), NAMESPACE)
    ##yada <- Module("yada", PACKAGE=NULL)
    ##print( yada$nbfills("trades.pb") )
    invisible(NULL)
}

suppressMessages(library(RProtoBuf))
suppressMessages(library(rbenchmark))

dyn.load("protoLoadForR.so")

print(benchmark(basicRuse = basicUse(FALSE),
                preAlloc  = preAlloc(FALSE),
                compiled  = compiled(FALSE),
                order = "elapsed",
                columns = c("test", "replications", "elapsed", "relative", "user.self", "sys.self"),
                replications  = 1))

#basicUse()
#preAlloc()
#inlined("trades-20100715-152816.pb")
#moduled("trades.pb")
