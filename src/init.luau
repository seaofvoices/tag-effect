local TagConfiguration = require('./TagConfiguration')
local createTagEffect = require('./createTagEffect')
local validation = require('./validation')

export type TagConfiguration = TagConfiguration.TagConfiguration

local function configure(): TagConfiguration
    return TagConfiguration.new()
end

return {
    configure = configure,
    createTagEffect = createTagEffect,
    validation = {
        verifyInstanceClass = validation.verifyInstanceClass,
    },
}
