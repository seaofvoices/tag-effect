local Teardown = require('@pkg/luau-teardown')
local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local TagConfiguration = require('../TagConfiguration')
local createTaggedInstance = require('./createTaggedInstance')

local expect = jestGlobals.expect
local it = jestGlobals.it
local describe = jestGlobals.describe
local jest = jestGlobals.jest
local beforeEach = jestGlobals.beforeEach
local afterEach = jestGlobals.afterEach

local cleanupFunctions = {}

afterEach(function()
    Teardown.teardown(cleanupFunctions)
    cleanupFunctions = {}
end)

local function cleanAfterTest(...: Teardown.Teardown | Instance)
    table.insert(cleanupFunctions, Teardown.fn(... :: any))
end

local tagCounter = 0
local tagName = `TestTag-0`

beforeEach(function()
    tagCounter += 1
    tagName = `TestTag-{tagCounter}`
end)

describe('new', function()
    it('creates a new TagConfiguration instance', function()
        local config = TagConfiguration.new()
        expect(config).never.toBeNil()
    end)
end)

describe('targetParent', function()
    it('returns a new object with targetParent flag set', function()
        local config = TagConfiguration.new()
        local parentConfig = config:targetParent()

        expect(parentConfig).never.toBe(config)
    end)

    it('applies the effect to the parent of the tagged instance', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local testParent = Instance.new('Part')
        cleanAfterTest(testParent)

        local cleanup = TagConfiguration.new():targetParent():effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local taggedInstance = createTaggedInstance('Configuration', tagName, testParent)
        cleanAfterTest(taggedInstance)

        testParent.Parent = workspace

        expect(effectFn).toHaveBeenCalledTimes(1)
        expect(effectFn).toHaveBeenCalledWith(testParent, nil, taggedInstance)
    end)
end)

describe('withDefaultConfig', function()
    it('returns a new object with default config', function()
        local config = TagConfiguration.new()

        local configWithDefaults = config:withDefaultConfig({ value = '' }, { value = 'string' })

        expect(configWithDefaults).never.toBe(config)
    end)

    it('merges the default config with the tagged instance attributes', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local cleanup = TagConfiguration.new()
            :withDefaultConfig({ color = 'blue', size = 5 })
            :effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local taggedInstance = createTaggedInstance('Folder', tagName, nil, {
            color = 'red',
        })
        cleanAfterTest(taggedInstance)

        expect(effectFn).toHaveBeenCalledTimes(1)
        expect(effectFn).toHaveBeenCalledWith(taggedInstance, { color = 'red', size = 5 })
    end)

    if _G.DEV then
        it('does not run the effect function if the config schema is not met', function()
            local effectFn = jest.fn(function()
                return function() end
            end)

            local cleanup = TagConfiguration.new()
                :withDefaultConfig({ color = 'blue' }, { color = 'string' })
                :effect(tagName, effectFn)
            cleanAfterTest(cleanup)

            local taggedInstance = createTaggedInstance('Folder', tagName, nil, {
                color = false,
            })
            cleanAfterTest(taggedInstance)

            expect(effectFn).never.toHaveBeenCalled()
        end)
    end

    it('re-runs the effect when an attribute changes', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local cleanup =
            TagConfiguration.new():withDefaultConfig({ color = 'blue' }):effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local taggedInstance = createTaggedInstance('Folder', tagName, nil, {
            color = 'red',
        })
        cleanAfterTest(taggedInstance)

        expect(effectFn).toHaveBeenCalledTimes(1)
        expect(effectFn).toHaveBeenCalledWith(taggedInstance, { color = 'red' })

        taggedInstance:SetAttribute('color', 'green')

        expect(effectFn).toHaveBeenCalledTimes(2)
        expect(effectFn).toHaveBeenCalledWith(taggedInstance, { color = 'green' })
    end)
end)

describe('withValidClass', function()
    it('returns a new object with valid classes', function()
        local config = TagConfiguration.new()
        local configWithClasses = config:withValidClass('Folder', 'Part')

        expect(configWithClasses).never.toBe(config)
    end)

    it('applies the effect to a valid class', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local cleanup = TagConfiguration.new():withValidClass('Part'):effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local validInstance = createTaggedInstance('Part', tagName)
        cleanAfterTest(validInstance)

        expect(effectFn).toHaveBeenCalledWith(validInstance)
    end)

    it('applies the effect to a derived class', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local cleanup = TagConfiguration.new():withValidClass('BasePart'):effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local validInstance = createTaggedInstance('Part', tagName)
        cleanAfterTest(validInstance)

        expect(effectFn).toHaveBeenCalledWith(validInstance)
    end)

    it('does not apply the effect to an invalid class', function()
        local effectFn = jest.fn(function()
            return function() end
        end)

        local cleanup = TagConfiguration.new():withValidClass('Part'):effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local invalidInstance = createTaggedInstance('Folder', tagName)
        cleanAfterTest(invalidInstance)

        expect(effectFn).never.toHaveBeenCalled()
    end)

    describe('with targetParent', function()
        it('applies the effect to a valid class', function()
            local effectFn = jest.fn(function()
                return function() end
            end)

            local cleanup = TagConfiguration.new()
                :targetParent()
                :withValidClass('Part')
                :effect(tagName, effectFn)
            cleanAfterTest(cleanup)

            local target = Instance.new('Part')
            target.Parent = workspace

            local validInstance = createTaggedInstance('Configuration', tagName, target)
            cleanAfterTest(validInstance)

            expect(effectFn).toHaveBeenCalledWith(target, nil, validInstance)
        end)

        it('applies the effect to a derived class', function()
            local effectFn = jest.fn(function()
                return function() end
            end)

            local cleanup = TagConfiguration.new()
                :targetParent()
                :withValidClass('BasePart')
                :effect(tagName, effectFn)
            cleanAfterTest(cleanup)

            local target = Instance.new('Part')
            target.Parent = workspace

            local validInstance = createTaggedInstance('Configuration', tagName, target)
            cleanAfterTest(validInstance)

            expect(effectFn).toHaveBeenCalledWith(target, nil, validInstance)
        end)

        it('does not apply the effect to an invalid class', function()
            local effectFn = jest.fn(function()
                return function() end
            end)

            local cleanup = TagConfiguration.new()
                :targetParent()
                :withValidClass('Part')
                :effect(tagName, effectFn)
            cleanAfterTest(cleanup)

            local target = Instance.new('Folder')
            target.Parent = workspace

            local invalidInstance = createTaggedInstance('Configuration', tagName, target)
            cleanAfterTest(invalidInstance)

            expect(effectFn).never.toHaveBeenCalled()
        end)
    end)
end)

describe('ignoreDescendantOf', function()
    it('returns a new object with ignore descendants', function()
        local config = TagConfiguration.new()
        local configWithIgnore = config:ignoreDescendantOf(workspace)

        expect(configWithIgnore).never.toBe(config)
    end)

    it('does not apply effect to instances that are descendants of ignored ancestors', function()
        local ignoreRoot = Instance.new('Folder')
        cleanAfterTest(ignoreRoot)

        local effectFn = jest.fn(function()
            return function() end
        end)

        local config = TagConfiguration.new():ignoreDescendantOf(ignoreRoot)
        local cleanup = config:effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local normalInstance = createTaggedInstance('Folder', tagName)
        local ignoredInstance = createTaggedInstance('Folder', tagName, ignoreRoot)
        cleanAfterTest(normalInstance, ignoredInstance)

        expect(effectFn).toHaveBeenCalledWith(normalInstance)
        expect(effectFn).never.toHaveBeenCalledWith(ignoredInstance)
    end)
end)

describe('includeDescendantOf', function()
    it('returns a new object with include descendants', function()
        local config = TagConfiguration.new()

        local configWithInclude = config:includeDescendantOf(workspace)

        expect(configWithInclude).never.toBe(config)
    end)

    it('applies effect to instances that are descendants of included ancestors', function()
        local includeRoot = Instance.new('Folder')
        includeRoot.Parent = workspace
        cleanAfterTest(includeRoot)

        local effectFn = jest.fn(function()
            return function() end
        end)

        local config = TagConfiguration.new():includeDescendantOf(includeRoot)
        local cleanup = config:effect(tagName, effectFn)
        cleanAfterTest(cleanup)

        local includedInstance = createTaggedInstance('Folder', tagName, includeRoot)
        local unrelatedInstance = createTaggedInstance('Folder', tagName)
        cleanAfterTest(includedInstance, unrelatedInstance)

        expect(effectFn).toHaveBeenCalledWith(includedInstance)
        expect(effectFn).never.toHaveBeenCalledWith(unrelatedInstance)
    end)
end)
