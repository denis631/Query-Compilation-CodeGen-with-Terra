struct User {
    id : int
    name : rawstring
}

struct Datastore {
    users : &User
    usersCount : int
}

loadDatastore = terra()
    -- TODO: Read & parse the data from disk
    var datastore = [&Datastore](C.malloc(sizeof(Datastore)))

    datastore.usersCount = 2
    var u = [&User](C.malloc(sizeof(User) * datastore.usersCount))

    for i = 0, datastore.usersCount do
        u[i].id = i
        u[i].name = "TEST"
    end
    datastore.users = u

    return datastore
end