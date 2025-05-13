local Teardown = require('@pkg/luau-teardown')
local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local createTagEffect = require('../createTagEffect')
local createTaggedInstance = require('./createTaggedInstance')

local expect = jestGlobals.expect
local it = jestGlobals.it
local jest = jestGlobals.jest
local beforeEach = jestGlobals.beforeEach
local afterEach = jestGlobals.afterEach

local cleanupFunctions = {}

local tagCounter = 0
local tagName = `TestTag-0`

beforeEach(function()
    tagCounter += 1
    tagName = `TestTag-{tagCounter}`
end)

afterEach(function()
    Teardown.teardown(cleanupFunctions)
    cleanupFunctions = {}
end)

local function cleanAfterTest(...: Teardown.Teardown | Instance)
    table.insert(cleanupFunctions, Teardown.fn(... :: any))
end

it('returns a cleanup function', function()
    local cleanup = createTagEffect(tagName, function()
        return nil
    end)
    expect(typeof(cleanup)).toBe('function')
    cleanup()
end)

it('runs the effect function for a newly created tagged instance', function()
    local effectFn = jest.fn(function()
        return function() end
    end)

    local cleanup = createTagEffect(tagName, effectFn)
    cleanAfterTest(cleanup)

    local instance = createTaggedInstance('Folder', tagName, workspace)
    cleanAfterTest(instance)

    expect(effectFn).toHaveBeenCalledTimes(1)
    expect(effectFn).toHaveBeenCalledWith(instance)
end)

it('runs the effect function for a newly created instance when the tag is added', function()
    local effectFn = jest.fn(function()
        return function() end
    end)

    local cleanup = createTagEffect(tagName, effectFn)
    cleanAfterTest(cleanup)

    local instance = Instance.new('Folder')
    instance.Parent = workspace
    cleanAfterTest(instance)

    expect(effectFn).never.toHaveBeenCalled()

    instance:AddTag(tagName)

    expect(effectFn).toHaveBeenCalledTimes(1)
    expect(effectFn).toHaveBeenCalledWith(instance)
end)

it('runs the effect function for an already tagged instance', function()
    local instance = createTaggedInstance('Folder', tagName)
    cleanAfterTest(instance)

    local effectFn = jest.fn(function()
        return function() end
    end)

    local cleanup = createTagEffect(tagName, effectFn)
    cleanAfterTest(cleanup)

    expect(effectFn).toHaveBeenCalledWith(instance)
end)

it('cleans up effects when a tag is removed', function()
    local cleanupFn = jest.fn()

    local effectFn = jest.fn(function()
        return function()
            cleanupFn()
        end
    end)

    local cleanup = createTagEffect(tagName, effectFn)
    cleanAfterTest(cleanup)

    local instance = createTaggedInstance('Folder', tagName, workspace)
    cleanAfterTest(instance)

    expect(effectFn).toHaveBeenCalledWith(instance)
    expect(cleanupFn).never.toHaveBeenCalled()

    instance:RemoveTag(tagName)

    expect(cleanupFn).toHaveBeenCalled()
end)

it('cleans up effects when the instance is un-parented', function()
    local cleanupFn = jest.fn()

    local effectFn = jest.fn(function()
        return function()
            cleanupFn()
        end
    end)

    local cleanup = createTagEffect(tagName, effectFn)
    cleanAfterTest(cleanup)

    local instance = createTaggedInstance('Folder', tagName, workspace)
    cleanAfterTest(instance)

    expect(effectFn).toHaveBeenCalledWith(instance)
    expect(cleanupFn).never.toHaveBeenCalled()

    instance.Parent = nil

    expect(cleanupFn).toHaveBeenCalled()
end)

it('cleans up all effects when the main cleanup function is called', function()
    local cleanupFn1 = jest.fn()
    local cleanupFn2 = jest.fn()

    local callCount = 0
    local effectFn = jest.fn(function()
        callCount += 1
        if callCount == 1 then
            return function()
                cleanupFn1()
            end
        else
            return function()
                cleanupFn2()
            end
        end
    end)

    local cleanup = createTagEffect(tagName, effectFn)

    local instance1 = createTaggedInstance('Folder', tagName, workspace)
    local instance2 = createTaggedInstance('Folder', tagName, workspace)
    cleanAfterTest(instance1, instance2)

    expect(effectFn).toHaveBeenCalledTimes(2)
    expect(cleanupFn1).never.toHaveBeenCalled()
    expect(cleanupFn2).never.toHaveBeenCalled()

    cleanup()

    expect(cleanupFn1).toHaveBeenCalled()
    expect(cleanupFn2).toHaveBeenCalled()
end)
