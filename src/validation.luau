local Disk = require('@pkg/luau-disk')

local Array = Disk.Array
local Map = Disk.Map

local function verifyInstanceClass(instance: Instance, classes: { string }): boolean
    if #classes == 0 then
        return true
    end
    for _, className in classes do
        if instance:IsA(className) then
            return true
        end
    end
    return false
end

local DEFAULT_FORMAT_LIST_CONFIG = {
    quote = "'",
    separator = 'or',
}

local function formatList(
    list: string | { string },
    config: { quote: string?, separator: string? }?
): string
    local list: { string } = if type(list) == 'string' then { list } else list
    local total = #list
    local config = Map.merge(DEFAULT_FORMAT_LIST_CONFIG, config)
    local quote = config.quote

    if total == 0 then
        return ''
    elseif total == 1 then
        return quote .. list[1] .. quote
    else
        local firsts = Array.range(list, -1)
        return `{quote}{table.concat(firsts, quote .. ', ' .. quote)}{quote} {config.separator} {quote}{list[total]}{quote}`
    end
end

local function formatInvalidTagClassMessage(
    tagName: string,
    instance: Instance,
    classes: { string }
): string
    return `unable to define '{tagName}' tag on a '{instance.ClassName}' instance ({instance:GetFullName()}),`
        .. ` it must inherit {formatList(classes)}`
end

local function getType(value: unknown): string
    local valueType = type(value)

    if valueType == 'userdata' or valueType == 'vector' then
        return typeof(value)
    end

    return valueType
end

local function getDisplayType(value: unknown): string
    local valueType = getType(value)

    if valueType == 'Instance' then
        return (value :: Instance).ClassName
    end

    return valueType
end

local function extractTypes(typeDefinition: string): { string }
    local expectedTypes = string.split(typeDefinition, '|')

    local lastType = expectedTypes[#expectedTypes]
    if string.sub(lastType, -1, -1) == '?' then
        expectedTypes[#expectedTypes] = string.sub(lastType, 1, -2)
        table.insert(expectedTypes, 'nil')
    end

    return expectedTypes
end

local function validateType(value: unknown, typeDefinition: string): boolean
    local valueType = getType(value)

    if valueType == 'Instance' then
        local value = value :: Instance
        return Array.any(extractTypes(typeDefinition), function(expectType)
            return valueType == expectType or value.ClassName == expectType or value:IsA(expectType)
        end)
    end

    return Array.any(extractTypes(typeDefinition), function(expectType)
        return valueType == expectType
    end)
end

local function formatInvalidConfigurationMessage(
    tagName: string,
    instance: Instance,
    member: string | { string },
    message: string
): string
    return `invalid {formatList(member)} configuration on '{instance:GetFullName()}' for '{tagName}' tag, {message}`
end

local function formatInvalidConfigurationMemberClass(
    tagName: string,
    instance: Instance,
    member: string,
    classes: string | { string }
): string
    return formatInvalidConfigurationMessage(
        tagName,
        instance,
        member,
        `unexpected class '{instance.ClassName}' (expected a {formatList(classes)})`
    )
end

local function formatInvalidConfigurationMemberSubClass(
    tagName: string,
    instance: Instance,
    member: string,
    classes: string | { string }
): string
    return formatInvalidConfigurationMessage(
        tagName,
        instance,
        member,
        `unexpected class '{instance.ClassName}' (expected a sub-class of {formatList(classes)})`
    )
end

return {
    verifyInstanceClass = verifyInstanceClass,
    formatList = formatList,
    formatInvalidTagClassMessage = formatInvalidTagClassMessage,
    formatInvalidConfigurationMessage = formatInvalidConfigurationMessage,
    formatInvalidConfigurationMemberClass = formatInvalidConfigurationMemberClass,
    formatInvalidConfigurationMemberSubClass = formatInvalidConfigurationMemberSubClass,
    extractTypes = extractTypes,
    getType = getType,
    getDisplayType = getDisplayType,
    validateType = validateType,
}
