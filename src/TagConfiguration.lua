local Disk = require('@pkg/luau-disk')
local Teardown = require('@pkg/luau-teardown')

local createTagEffect = require('./createTagEffect')
local validation = require('./validation')

local Array = Disk.Array
local Map = Disk.Map

type Teardown = Teardown.Teardown

local OBJECT_ATTRIBUTE_TAG = 'ObjectAttribute'

export type TagConfiguration = {}

type Private = {
    _useParent: boolean,
    _defaultConfig: { [string]: any }?,
    _configSchema: { [string]: string }?,
    _validClasses: { string },
    _ignoreDescendantOf: { Instance },
    _includeDescendantOf: { Instance },
}
type PrivateTagConfiguration = TagConfiguration & Private

type TagConfigurationStatic = TagConfiguration & Private & {
    new: () -> TagConfiguration,
    targetParent: (self: TagConfiguration) -> TagConfiguration,
    withDefaultConfig: (
        self: TagConfiguration,
        config: { [string]: any },
        schema: { [string]: string }?
    ) -> TagConfiguration,
    withValidClass: (self: TagConfiguration, ...string) -> TagConfiguration,
    ignoreDescendantOf: (self: TagConfiguration, ...Instance) -> TagConfiguration,
    includeDescendantOf: (self: TagConfiguration, ...Instance) -> TagConfiguration,
    effect: (self: TagConfiguration, tagName: string, fn: (Instance) -> Teardown) -> () -> (),
}

local TagConfiguration: TagConfigurationStatic = {} :: any
local TagConfigurationMetatable = {
    __index = TagConfiguration,
}

local function new(self: Private): TagConfiguration
    return setmetatable(self, TagConfigurationMetatable) :: any
end

function TagConfiguration.new(): TagConfiguration
    local self: Private = {
        _useParent = false,
        _validClasses = {},
        _defaultConfig = nil,
        _ignoreDescendantOf = {},
        _includeDescendantOf = {},
    }

    return new(self)
end

function TagConfiguration:targetParent(): TagConfiguration
    local self: PrivateTagConfiguration = self :: any
    if self._useParent then
        return self :: any
    else
        local copied: Private = table.clone(self) :: any
        copied._useParent = true
        return new(copied)
    end
end

function TagConfiguration:withDefaultConfig(
    config: { [string]: any },
    schema: { [string]: string }?
): TagConfiguration
    local self: PrivateTagConfiguration = self :: any
    local copied: Private = table.clone(self) :: any
    copied._defaultConfig = config
    copied._configSchema = schema
    return new(copied)
end

function TagConfiguration:withValidClass(...: string): TagConfiguration
    local self: PrivateTagConfiguration = self :: any
    local copied: Private = table.clone(self) :: any
    copied._validClasses = Array.push(copied._validClasses, ...)
    return new(copied)
end

function TagConfiguration:ignoreDescendantOf(...: Instance): TagConfiguration
    local self: PrivateTagConfiguration = self :: any
    local copied: Private = table.clone(self) :: any
    copied._ignoreDescendantOf = Array.push(copied._ignoreDescendantOf, ...)
    return new(copied)
end

function TagConfiguration:includeDescendantOf(...: Instance): TagConfiguration
    local self: PrivateTagConfiguration = self :: any
    local copied: Private = table.clone(self) :: any
    copied._includeDescendantOf = Array.push(copied._includeDescendantOf, ...)
    return new(copied)
end

function TagConfiguration:effect(tagName: string, fn: (Instance) -> Teardown): () -> ()
    local self: PrivateTagConfiguration = self :: any

    local useParent = self._useParent
    local defaultConfig = self._defaultConfig
    local configSchema = self._configSchema
    local validClasses = Array.deduplicate(self._validClasses)
    local ignoreDescendantOf = Array.deduplicate(self._ignoreDescendantOf)
    local includeDescendantOf = Array.deduplicate(self._includeDescendantOf)
    local checkIncludeDescendantOf = #includeDescendantOf > 0

    local validateClasses
    if #validClasses > 0 then
        function validateClasses(target: Instance): boolean
            if not validation.verifyInstanceClass(target, validClasses) then
                if _G.DEV then
                    warn(validation.formatInvalidTagClassMessage(tagName, target, validClasses))
                end
                return false
            end
            return true
        end
    end

    return createTagEffect(tagName, function(object: Instance): Teardown
        if
            Array.any(ignoreDescendantOf, function(ancestor)
                return object:IsDescendantOf(ancestor)
            end)
        then
            return nil
        end
        if
            checkIncludeDescendantOf
            and not Array.any(includeDescendantOf, function(ancestor)
                return object:IsDescendantOf(ancestor)
            end)
        then
            return nil
        end

        if defaultConfig == nil then
            if useParent then
                local lastRefreshCleanup: Teardown = nil

                local function refresh()
                    Teardown.teardown(lastRefreshCleanup)
                    lastRefreshCleanup = nil

                    local target = if useParent then object.Parent else object

                    if target ~= nil and validateClasses and not validateClasses(target) then
                        if useParent then
                            lastRefreshCleanup =
                                object:GetPropertyChangedSignal('Parent'):Connect(refresh) :: any
                        end
                        return
                    end

                    lastRefreshCleanup = Teardown.join(
                        object:GetPropertyChangedSignal('Parent'):Connect(refresh) :: any,
                        if target ~= nil then (fn :: any)(target) else nil
                    )
                end

                refresh()

                return function()
                    Teardown.teardown(lastRefreshCleanup)
                end
            else
                return fn(object)
            end
        end

        local lastRefreshCleanup: Teardown = nil

        local function refresh()
            Teardown.teardown(lastRefreshCleanup)
            lastRefreshCleanup = nil

            local target = if useParent then object.Parent else object

            if target ~= nil and validateClasses and not validateClasses(target) then
                if useParent then
                    lastRefreshCleanup =
                        object:GetPropertyChangedSignal('Parent'):Connect(refresh) :: any
                end
                return
            end

            local readConfig = object:GetAttributes()
            local children = object:GetChildren()
            local objectValueAttributes: { ObjectValue } = Array.filter(children, function(child)
                return child.ClassName == 'ObjectValue' and child:HasTag(OBJECT_ATTRIBUTE_TAG)
            end) :: { any }

            for _, objectValue in objectValueAttributes do
                readConfig[objectValue.Name] = objectValue.Value
            end

            local config = Map.merge(defaultConfig, readConfig)

            if _G.DEV and configSchema ~= nil then
                for propertyName, typeName in configSchema do
                    local value = config[propertyName]

                    if not validation.validateType(value, typeName) then
                        if value == nil then
                            warn(
                                `missing '{propertyName}' configuration on '{object:GetFullName()}'`
                                    .. ` for '{tagName}' tag`
                            )
                        else
                            warn(
                                `invalid '{propertyName}' configuration on '{object:GetFullName()}' for`
                                    .. ` '{tagName}' tag, {typeName} value expected but received `
                                    .. `{validation.getDisplayType(value)} value ({tostring(value)})`
                            )
                        end
                        return
                    end
                end
            end

            local dynamicConnections: { [Instance]: RBXScriptConnection } = {}

            lastRefreshCleanup = Teardown.join(
                object.AttributeChanged:Connect(refresh) :: any,
                object.ChildAdded:Connect(function(newChild: Instance)
                    if newChild.ClassName == 'ObjectValue' then
                        if newChild:HasTag(OBJECT_ATTRIBUTE_TAG) then
                            refresh()
                        else
                            dynamicConnections[newChild] = newChild
                                :GetAttributeChangedSignal(OBJECT_ATTRIBUTE_TAG)
                                :Connect(refresh)
                        end
                    end
                end) :: any,
                object.ChildRemoved:Connect(function(child: Instance)
                    local connection = dynamicConnections[child]
                    if connection then
                        dynamicConnections[child] = nil
                        connection:Disconnect()
                    end
                end) :: any,
                function()
                    for _, connection in dynamicConnections do
                        connection:Disconnect()
                    end
                    dynamicConnections = {}
                end,
                Array.map(objectValueAttributes, function(objectValue)
                    return objectValue.Changed:Connect(refresh)
                end),
                if useParent
                    then object:GetPropertyChangedSignal('Parent'):Connect(refresh) :: any
                    else nil,
                if target ~= nil then (fn :: any)(target, config) else nil
            )
        end

        refresh()

        return function()
            Teardown.teardown(lastRefreshCleanup)
        end
    end)
end

return TagConfiguration
