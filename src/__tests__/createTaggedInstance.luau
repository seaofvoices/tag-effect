local function createTaggedInstance(
    className: string,
    tagName: string,
    parent: Instance?,
    attributes: { [string]: any }?
)
    local instance = Instance.new(className)

    if attributes then
        for name, value in pairs(attributes) do
            instance:SetAttribute(name, value)
        end
    end

    instance:AddTag(tagName)

    instance.Parent = parent or game:GetService('Workspace')

    return instance
end

return createTaggedInstance
