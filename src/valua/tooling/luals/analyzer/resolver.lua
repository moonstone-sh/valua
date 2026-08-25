local resolver = {}

function resolver.create()
    local symbols = {}

    local self = {}

    function self.set(name, schema_type)
        symbols[name] = schema_type
    end

    function self.get(name)
        return symbols[name]
    end

    return self
end

return resolver
