local jestGlobals = require('@pkg/@jsdotlua/jest-globals')

local validation = require('../validation')

local expect = jestGlobals.expect
local it = jestGlobals.it
local describe = jestGlobals.describe

describe('getType', function()
    for value, expectType in
        {
            [true :: any] = 'boolean',
            [false] = 'boolean',
            [0] = 'number',
            [-1] = 'number',
            [10] = 'number',
            [math.huge] = 'number',
            [''] = 'string',
            ['123'] = 'string',
            ['abc'] = 'string',
            [Vector3.one] = 'Vector3',
            [Vector2.one] = 'Vector2',
            [UDim2.fromScale(1, 1)] = 'UDim2',
            [UDim.new(1, 0)] = 'UDim',
            [Instance.new('Folder')] = 'Instance',
            [Instance.new('Part')] = 'Instance',
        }
    do
        it(`returns '{expectType}' for {value}`, function()
            expect(validation.getType(value)).toEqual(expectType)
        end)
    end

    it(`returns 'nil' for nil value`, function()
        expect(validation.getType(nil)).toEqual('nil')
    end)
end)

describe('validateType', function()
    local validCases: { { any } } = {
        { 'boolean', true },
        { 'boolean', false },
        { 'number', 1 },
        { 'number', math.huge },
        { 'number', -80 },
        { 'string', '' },
        { 'string', '11' },
        { 'string', 'abc' },
        { 'Vector3', Vector3.zAxis },
        { 'Vector2', Vector2.xAxis },
        { 'Instance', Instance.new('Configuration') },
        { 'Instance', Instance.new('Folder') },
        { 'Folder', Instance.new('Folder') },
        { 'BasePart', Instance.new('Part') },
        { 'boolean?', nil },
        { 'string?', nil },
        { 'Vector3?', nil },
        { 'Instance?', nil },
        { 'UDim2?', nil },
        { 'Folder?', nil },
        { 'boolean|number', false },
        { 'boolean|number', 1 },
        { 'boolean|number|string', true },
        { 'boolean|number|string', false },
        { 'boolean|number|string', 1 },
        { 'boolean|number|string', '' },
        { 'boolean|number|string?', nil },
    }

    local invalidCases: { { any } } = {
        { 'boolean', nil },
        { 'boolean', 1 },
        { 'number', '' },
        { 'number', true },
        { 'number', nil },
        { 'string', nil },
        { 'string', 1 },
        { 'string', true },
        { 'Vector3', Vector2.one },
        { 'Vector2', Vector3.xAxis },
        { 'Instance', true },
        { 'Instance', 1 },
        { 'Folder', 'abc' },
        { 'boolean?', '' },
        { 'string?', false },
        { 'Vector3?', 1 },
        { 'Instance?', 'ok' },
        { 'UDim2?', Vector3.one },
        { 'Folder?', UDim.new(0.5, 20) },
        { 'boolean|number', '' },
        { 'boolean|number', Instance.new('Folder') },
        { 'BasePart', Instance.new('Folder') },
    }

    for _, case in validCases do
        it(`is true for {case[2]} with type '{case[1]}'`, function()
            expect(validation.validateType(case[2], case[1])).toEqual(true)
        end)
    end

    for _, case in invalidCases do
        it(`is false for {case[2]} with type '{case[1]}'`, function()
            expect(validation.validateType(case[2], case[1])).toEqual(false)
        end)
    end
end)
