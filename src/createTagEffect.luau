local CollectionService = game:GetService('CollectionService')

local Teardown = require('@pkg/luau-teardown')

type Teardown = Teardown.Teardown

local function createTagEffect(tagName: string, fn: (Instance) -> Teardown): () -> ()
    local taggedTeardowns = {}

    local function onTagAdded(instance: Instance)
        if _G.DEBUG_TAG_EFFECT then
            print(
                `new instance '{instance.Name}' tagged {tagName}`
                    .. if instance.Parent then ` ({instance.Parent:GetFullName()})` else ''
            )
        end
        local bin = taggedTeardowns[tagName]
        if bin == nil then
            bin = {}
            taggedTeardowns[tagName] = bin
        end

        if bin[instance] ~= nil then
            Teardown.teardown(bin[instance])
            bin[instance] = nil
        end

        bin[instance] = fn(instance)
    end

    local addedConnection = CollectionService:GetInstanceAddedSignal(tagName):Connect(onTagAdded)

    local removedConnection = CollectionService:GetInstanceRemovedSignal(tagName)
        :Connect(function(instance: Instance)
            if _G.DEBUG_TAG_EFFECT then
                print(`cleanup '{instance.Name}' tagged {tagName}`)
            end
            local bin = taggedTeardowns[tagName]

            if bin and bin[instance] then
                Teardown.teardown(bin[instance])
                bin[instance] = nil
            end
        end)

    for _, current in CollectionService:GetTagged(tagName) do
        xpcall(onTagAdded, function(err)
            warn(
                `unable to apply tag '{tagName}' on {current.Name} ({current:GetFullName()}): {err}`
            )
        end, current)
    end

    local function cleanEffect()
        Teardown.teardown(addedConnection :: any, removedConnection :: any)
        for _, teardown in taggedTeardowns do
            Teardown.teardown(teardown)
        end
        taggedTeardowns = {}
    end

    return cleanEffect
end

return createTagEffect
