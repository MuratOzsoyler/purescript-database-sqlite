'use strict'

const sqlite = require("sqlite3")

exports.oPEN_READONLY = sqlite.OPEN_READONLY
exports.oPEN_READWRITE = sqlite.OPEN_READWRITE
exports.oPEN_CREATE = sqlite.OPEN_CREATE

exports.newImpl = path => mode => (onError, onSuccess) => {
    let errOccurred = false
    let db = new sqlite.Database(path, mode, err => {
        if (err) {
            errOccurred = true
            onError(err)
        }
    })
    if (!errOccurred)
        onSuccess(db)
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.closeImpl = db => (onError, onSuccess) => {
    db.close(err => {
        if (err)
            onError(err)
        else
            onSuccess()
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.runImpl = db => query => params => (onError, onSuccess) => {
    db.run(query, params, function (err) {
        if (err)
            onError(err)
        else
            onSuccess({ lastID: this.lastID, changes: this.changes })
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.getImpl = db => query => params => (onError, onSuccess) => {
    db.get(query, params, (err, row) => {
        if (err)
            onError(err)
        else
            onSuccess(row)
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.allImpl = db => query => params => (onError, onSuccess) => {
    db.all(query, params, (err, rows) => {
        if (err)
            onError(err)
        else
            onSuccess(rows)
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.eachImpl = db => query => params => cb => (onError, onSuccess) => {
    db.each(query, params,
        (err, row) => {
            if (err)
                onError(err)
            else
                cb(row)
        },
        (err, affected) => {
            if (err)
                onError(err)
            else
                onSuccess(affected)
        })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.execImpl = db => query => (onError, onSuccess) => {
    db.exec(query, err => {
        if (err)
            onError(err)
        else
            onSuccess()
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.prepareImpl = db => query => params => (onError, onSuccess) => {
    let errorOccurred = false
    const stmt = db.prepare(query, params, err => {
        if (err) {
            errorOccurred = true
            onError(err)
        }
    })
    if (!errorOccurred)
        onSuccess(stmt)
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtFinalizeImpl = stmt => (onError, onSuccess) => {
    stmt.finalize(err => {
        if (err)
            onError(err)
        else
            onSuccess()
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtResetImpl = stmt => (onError, onSuccess) => {
    stmt.reset(err => {
        if (err)
            onError(err)
        else
            onSuccess()
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtBindImpl = stmt => params => (onError, onSuccess) => {
    stmt.bind(params, err => {
        if (err)
            onError(err)
        else
            onSuccess()
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtGetImpl = stmt => params => (onError, onSuccess) => {
    stmt.get(params, (err, row) => {
        if (err)
            onError(err)
        else
            onSuccess(row)
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtRunImpl = stmt => params => (onError, onSuccess) => {
    console.log("stmtRunImpl: ffi started")
    let errorOccurred = false
    const result = stmt.run(params, function (err) {
        if (err) {
            errorOccurred = true
            console.log(`stmtRunImpl: error ${err}`)
            onError(err)
        }
        else {
            console.log(`stmtRunImpl: success lastId=${this.lastID}, changes=${this.changes}`)
            onSuccess({ lastID: this.lastID, changes: this.changes })
        }
    })
    console.log("stmtRunImpl: ffi exited")
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtAllImpl = stmt => params => (onError, onSuccess) => {
    stmt.all(params, (err, rows) => {
        if (err)
            onError(err)
        else
            onSuccess(rows)
    })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.stmtEachImpl = stmt => params => cb => (onError, onSuccess) => {
    stmt.each(params,
        (err, row) => {
            if (err)
                onError(err)
            else
                cb(row)
        },
        (err, affected) => {
            if (err)
                onError(err)
            else
                onSuccess(affected)
        })
    return (cancelError, onCancelerError, onCancelerSuccess) => onCancelerSuccess()
}

exports.verbose = () => {
    sqlite.verbose()
}
