[![checks](https://github.com/seaofvoices/tag-effect/actions/workflows/test.yml/badge.svg)](https://github.com/seaofvoices/tag-effect/actions/workflows/test.yml)
![version](https://img.shields.io/github/package-json/v/seaofvoices/tag-effect)
[![GitHub top language](https://img.shields.io/github/languages/top/seaofvoices/tag-effect)](https://github.com/luau-lang/luau)
![license](https://img.shields.io/npm/l/@seaofvoices/tag-effect)
![npm](https://img.shields.io/npm/dt/@seaofvoices/tag-effect)

# TagEffect

A Luau library to facilitate the application of effects to tagged instances within Roblox.

## Installation

Add `@seaofvoices/tag-effect` in your dependencies:

```bash
yarn add @seaofvoices/tag-effect
```

Or if you are using `npm`:

```bash
npm install @seaofvoices/tag-effect
```

## Features

- **Behavior Management**: Easily apply effects to instances tagged with specific tags using simple Lua functions.
- **Dynamic Configuration**: Configure effects with customizable parameters to achieve desired behavior.
- **Flexible Teardown**: Automatically manage resource cleanup using the Teardown types from [luau-teardown](https://github.com/seaofvoices/luau-teardown).
- **Debugging Support**: Enable debug mode to gain insights into the application of effects for easier troubleshooting.

## Content

### `createTagEffect`

```lua
TagEffect.createTagEffect(tagName: string, fn: (Instance) -> Teardown): () -> ()
```

This function is used to create effects that can be applied to instances tagged with specific given tag. It takes a tag name and a callback function as arguments, allowing you to define the behavior of the effect.

The callback function can return anything that can be cleaned up by [luau-teardown](https://github.com/seaofvoices/luau-teardown): RBXScriptConnections, Instances, `thread` objects, functions, and even arrays of any of these.


### `configure`

This function creates a new `TagConfiguration` object. This builder-like interface can be used to define powerful effects that:

- validates if the tagged instances are of the expected class
- filter tagged instances:
    - that are descendant of certain instances
    - that are not descendant of certain instances
- can read attributes (and nested `ObjectValue` instances, since Instance attributes are not supported) into a table, and:
    - validate that the expected attributes have correct types
    - merge the data with a default value
    - re-apply the effect when attributes changes

```lua
TagEffect.configure(): TagConfiguration
```

### TagConfiguration Methods

This class is a builder-like class.

#### `:effect(tagName: string, fn: (Instance) -> Teardown): () -> ()`

Defines the effect to be applied to instances tagged with the specified tag name. This method wraps the provided effect function with the configured parameters.

Returns a cleanup function to unregister effect.

- `tagName`: the tag name to associate with the effect.
- `fn`: the effect function to be applied to tagged instances. This function should accept an instance as its parameter and return a teardown function.

#### `:targetParent(): TagConfiguration`

Specifies that the effect should be applied to the parent of the tagged instance rather than the instance itself.

Returns a new TagConfiguration object.

#### `:withDefaultConfig(config: { [string]: any }, schema?: { [string]: string }): TagConfiguration`

Enables effect configuration loading and sets default configuration values for the effect. Returns a new TagConfiguration object.

**Arguments**
- `config`: a table containing default configuration values.
- `schema` (optional): a table defining the expected types for configuration

The effect configuration is read from its attributes and nested ObjectValue (since Instance attributes are not supported). The nested ObjectValue instances must have a `ObjectAttribute` attribute attached to them in order to be read into the configuration value.

This configuration value is passed to the effect function.

Optionally, a schema can be provided to enforce type validation for the configuration values.

The schema is a table that maps each property of the effect configuration to a type name. The type name can end with a `?` to mark it as optional. Union with `|` is also supported

Examples of valid type name:

- `boolean`
- `string`
- `number`
- `Vector3`
- `UDim2`
- `Instance`
- `string?`
- `BoolValue`
- `number|string`

#### `:withValidClass(...classNames: string): TagConfiguration`

Specifies valid class names that the tagged instance should have for the effect to be applied. If specified, the effect will only be applied to instances with one of the specified classes.

- `...classNames`: One or more class names as strings.

Returns a new TagConfiguration object.

#### `:ignoreDescendantOf(...ancestors: Instance): TagConfiguration`

The effect will not be applied to instances that are descendants of any of the specified ancestors.

- `...ancestors`: one or more instances to be ignored.

Returns a new TagConfiguration object.

#### `:includeDescendantOf(...ancestors: Instance): TagConfiguration`

When specified, the effect will only be applied to instances that are descendants of any of the specified ancestors.

- `...ancestors`: one or more instances to be included.

Returns a new TagConfiguration object.

## License

This project is available under the MIT license. See [LICENSE.txt](LICENSE.txt) for details.
