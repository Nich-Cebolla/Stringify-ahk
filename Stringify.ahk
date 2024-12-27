
/*
    - Added `nlCharLimitAll`
    - need to describe how to ignoreProp items in an array
    - chaned hideErrors to printErrors
    - @property {Boolean} [printBuiltinProps]
      If you are unsure which to use, `2` should be fine for most cases, as it excludes built-in methods
      and properties that don't have an inherent value; these things generally aren't needed when
      exporting data. `1` might be the better choice if one of these are true: you are using `Stringify`
      for something that is specifically AHK-related, and having access to the names of class methods
      and dynamic properties would be beneficial; or the object(s) being stringified have dynamic properties
      with a `Get` method that you do -not- want called when stringifying the object, but you do want
      to get . If neither of these
      are true, `2` is probably better.
            @property {Boolean} [singleLine] - When true, the entire JSON string is printed in a single line
      (no newlines or indentation). This option supersedes any other related option
            @property {Boolean} [printBuiltinProps] - This option only impacts instances of built-in classes.
      When true, `Stringify` will attempt to get the values of all properties, including the values
      of built-in properties such as `length`, and `capacity`, which are usually skipped. `Stringify`
      will work its way up the class inheritance chain until it reaches `Any`, attempting to get the
      values for each inherited property along the way. If the value is successfullyretrieved, it
      is printed the same as any other value. if the value fails to be retrieved, `Stringify`'s
      behavior depends on the options in use related to printing placeholders.
      This option may slow down `Stringify` when used with objects that have a deep nested structure.

      changed `showErrors` to `printErrors`

     
      changed `useOwnProps` to `callOwnProps`

      changed `quoteNumbersAsKey` to `quoteNumericKeys`

      changed `useEnum` to `callEnum`, and modified its functionality.

      changed `params` to a class

      limitation - in order for the recursepRevention to work, it needs to be able to assign a tag
      to the objects. if the objects have a `__Set` method that prevents this, then it will throw an error
*/

/*
-- escapeNL - setter - regexreplace
printErrors - all enum  sequences that include error handling
printfuncplaceholders - setter that handles objcets
printplacehodlers - when maxDepth is reached; when non-iterable object; when error occurs when accessing a value, when recursePrevention
-- printtypetag - in
itemContainerArray - enum array that has added properties
itemContainerEnum - all enum calls
itemCOntainerMap - map obj enum, any obj enum and the map test returns true, any obj enum and enumAsMap

callEnum - if number and not zero, all objects. if string, parse string and include type check. if type check, enum, else continue.

callOwnProps - if number and not zero and not two, all objects in 1-p mode. if 2, all objets in 2-p mode. If string, parse string and set type chck

enumAsMap - include check for map flag after performing map test, route fn to use map obj notation

printbuiltinprops - standalone option that has no impact on the other components. if true, send to builtinprops fn

-- ignoreProp - if ignoreProp, include check to ignoreProp list on all prop

-- recursePrevention - if recurseprevention, inlude recurse check before all recursion into nested objects

-- indent - literal string
-- maxdepth - if maxdepth, include check before all recursion into nested objects
-- newline - literal string
-- nlDepthLimit - if nlDepthLimit, include check before all recursion into nested objects.
    if currently == and going into a recursion, increment singleLineActive
    if currently == limit +1 and exiting a recursion, decrement singleLineActive
   
-- singline - if singleline, disable all newlines and indentation

singleline array / map / obj - if true, include in the opening sequence a function to modify the newline values
for that segment, and then to change it back when exiting

-- nlcharlimit array / map / obj - if true, include function calls to `ToggleSingleLine`. The outline looks like this:
prior to constructing that object's portion of the JSON string, get the current character count. This is facilitated
by `ToggleSingleLine`. When `TSL` is called, it firs checks if there is a positive value for this.singleLineActive. If so,
`this.singlelineActive` is incremented and it skips getting the character count since we already know this object will be
printed on a single line. If zero, then the count is registered for that object, and also the amount of "uncountedChars"
at that time. Control is returned
back to the main procedure, and the string is constructed. When finished, `TSL` is called again but with false on the
first parameter. If this.singleLinective is a positive value, it is decremented. If zero, the character count is compared
to the original minus any difference in uncountedcharacters, and if that number is beneath the limit from the option,
all exterior whitespace characters are removed, and that portion of the string is now on a single line.
*/

; #Include *i StringifyConfig.ahk



class Stringify {

    class params {
        ; Enum options
        static callOwnProps := 2
        static ignoreProps := []
        static ignoreKeys := []
        static propsList := ''
        static recursePrevention := 1

        ; Newline and indent options
        static indent := '`s`s`s`s'
        static newline := '`r`n'
        static maxDepth := 0
        static nlDepthLimit := 0
        ; The singleLine options supersede nlCharLimit options
        static singleLine := false
        static singleLineArray := false
        static singleLineMap := false
        static singleLineObj := false
        static nlCharLimitAll := 0
        static nlCharLimitArray := 0
        static nlCharLimitMap := 0
        static nlCharLimitObj := 0
        static nlCharLimitMapItems := 0

        ; Print options
        static escapeNL := ''
        static printErrors := false
        static printPlaceholders := false
        static quoteNumericKeys := true
        static printTypeTag := true
        static itemContainerArray := '__ArrayItem'
        static itemContainerMap := '__MapItem'
        static unsetArrayItem := '""'

        ; Misc options
        static returnString := false
        static deleteTags := true
        static throwErrors := true
        
        __New(obj, params) {
            for key, val in Stringify.Params.OwnProps() {
                this.%key% := params.HasOwnProp(key) ? params.%key% : IsSet(StringifyConfig)
                && StringifyConfig.HasOwnProp(key) ? StringifyConfig.%key% : val
            }
        }
        ; __New(obj, params) {
        ;     this.params := params
        ;     this.DefineProp('__Get', {Call:_Get_})

        ;     _Get(self, prop, *) {
        ;         if self.params.HasOwnProp(prop)
        ;             return self.params.%prop%
        ;         else if IsSet(StringifyConfig) && StringifyConfig.HasOwnProp(prop)
        ;             return StringifyConfig.%prop%
        ;         else
        ;             return Stringify.params.%prop%
        ;     }
        ; }
    }
    static patternNonIterables := '\bFunc\b|\bBoundFunc\b|\bEnumerator\b|\bClosure\b|\bComValue\b'
    
    ;@region Call
    /** ### Stringify()
     * Available options to pass in the `params` object. See the StringifyConfig.ahk document or
     * the README.md {@link https://github.com/Nich-Cebolla/Stringify-ahk} document for full details.
     * @param {obj} obj - The object to be stringified.
     * @param {String} [str] - For large JSON strings, receiving the string as a VarRef variable will
     * be slightly faster than as a returned string. For short JSON strings, the difference is likely
     * negligible.
     * @param {Object} [params] - An object containing options for the stringification process.
     * @property {String} [escapeNL] - The literal string of characters to replace matches with `\R`.
     * @property {Boolean|String} [printErrors] - When true, if an error occurs when attempting to
     * access a property or value, the error text is printed next to the placeholder. You can also assign
     * this a string value, where the string indicates which error property to include in the printed
     * text. Use only the first letter of the property name. The available properties are: `Message`,
     * `What`, `Extra`, `File`, `Line`, and `Stack`. An additional option is `T`, which will print
     * the type of error as `Type(err)`. A separator character is optional. For example, writing
     * `ML` will direct `Stringify` to only print the `Message` and `Line` property. Information is
     * printed in the order it is listed in the option's value.
     * @property {Array|String} [ignoreProps] - A string or array of strings containing property
     * names / object paths that will not be stringified. This is only in effect when iterating an
     * objects' `OwnProps()` method. To unambiguously exclude a property from a specific object,
     * write the string using the full path beginning with "$.". For example, if I have a nested object
     * on a property called "HairColor", and I want to exclude that one specifically for my "Brother"
     * but not my "Sister", I would write "$.MyFamily.Brother.HairColor". If I want to exclude all
     * properties named "HairColor", I just write "HairColor". The "$." represents the root object,
     * and so in this example, "MyFamily" is a property of the root object, not the root object itself.
     * Note that map keys are represented using map/array notation, so when writing the object path,
     * be sure to use the proper notation in places where the access point is a map item, not a object
     * property. For example, say "MyFamily" is a map object, then the string is
     * '$.MyFamily["Brother"].HairColor'. Use double quotes for these map keys.
     * @property {Array|String} [ignoreKeys] - A string or array of strings containing map keys
     * that will not be stringified. All map objects will have their keys compared to the values in
     * `ignoreKeys`. If a key matches, it is skipped. This is only in effect when iterating the
     * values of a map object.
     * @property {String} [indent] - The literal string to use as indentation.
     * @property {String} [itemContainerArray] - The name given to the faux array container.
     * @property {String} [itemContainerMap] - The name given to the faux map container.
     * @property {Number} [maxDepth] - The maximum depth that will be recursed into and stringified.
     * `0` means no limit.
     * @property {String} [newline] - The literal string used for new lines.
     * @property {Integer} [nlDepthLimit] - The maximum depth at which newlines will be printed in
     * the JSON string. When this option is 0, it is not in effect.
     * @property {Integer} [nlCharLimitAll] - When an object's stringification is complete, if the
     * length of the object's string representation is under this number (character count), it is
     * condensed to one line. This value supersedes the other three values. When this is 0, it is
     * not in effect.
     * @property {Integer} [nlCharLimitArray] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @property {Integer} [nlCharLimitMap] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @property {Integer} [nlCharLimitObj] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @property {Boolean} [printFuncPlaceholders] - When true, functions are represented in the JSON string
     * as "{Func}", "{BoundFunc}", or "{Closure}". This option works separately from `printPlaceholders`.
     * @property {Boolean} [printPlaceholders] - When true, if a property of item is not stringified, a
     * placeholder is printed in its stead, generally in the form `"{Type(obj)}"`. The exception is when
     * the type is `Class`. Since this is ambiguous, the placeholder is `"{Class: obj.prototype.__Class}"`.
     * This option works separately fron `printFuncPlaceholders`; `printPlaceholders` has no impact
     * on function objects.
     * @property {Boolean} [quoteNumericKeys] - When true, map keys that are numbers are always quoted.
     * When false, numbers that are map keys are printed as numbers without quotes.
     * @property {Integer|String} [recursePrevention] - Valid values are: 0 or false - no protection
     * 1 - `Stringify` allows multiple stringifications, but will not recurse into any objects that
     * would cause infinite recursion due to having a property that is also a parent object.
     * 2 - Enforces a maximum of one stringification per object.
     * @property {Boolean} [singleLine] - When true, the entire JSON string is printed in a single line
     * (no newlines or indentation). This option supersedes any other related option.
     * @property {Boolean} [singleLineArray] - All arrays are condensed to a single line each.
     * @property {Boolean} [singleLineMap] - All maps are condensed to a single line each.
     * @property {Boolean} [singleLineObj] - All objects are condensed to a single line each.
     * @property {Boolean} [enumPropsFirst] - This is only relevant when `callOwnProps` is true, and
     * the object being stringified is a map or an array (or has nested objects that are a map or
     * array). When true, `Stringify` will call `OwnProps()` first before calling `__Enum()` for all
     * map and array objects. When false, `Stringify` will call `__Enum()` first before calling
     * `OwnProps()`.
     * @property {Boolean} [printTypeTag] - When true, `Stringify` prints information about the type
     * of object in its segment of the JSON string. It is printed as a property called `__StringifyTypeTag`.
     * `__StringifyTypeTag` serves these functions: - It speeds up parsing because arrays don't need to be
     * validated as either map or array; - It enables the parser to restore the object to its original type.
     * Without this tag, the parser cannot restore the JSON objects into their type. It is deleted from
     * the objects upon exit, and will be in the JSON string only.
     * @property {Boolean|Integer|String} [callOwnProps] - `callOwnProps` controls `Stringify`'s behavior
     * when using the built-in `Object.Prototype.OwnProps()` method. These options are available:
     * - 0: No objects will call `OwnProps()`.
     * - 1: All objects will call `OwnProps()` in its 1-parameter mode. {@link https://www.autohotkey.com/docs/v2/lib/Object.htm#OwnProps}
     * - 2: All objects will call `OwnProps()` in its 2-parameter mode.
     * - String: A string containing a list of object types for which you want `Stringify` to call `OwnProps()`.
     * The object types should be separated by space or tab. By default, the 2-parameter mode will be used.
     * You can explicitly set the mode by including a colon with the number after each type name. For
     * example, say I have a class called `Automator` and another class called `TypeLibrary`, and I want
     * to use different modes for them, I can write: `Automator:1 TypeLibrary:2`. If a type is not
     * included in the list, `Stringify` does not call `OwnProps()` for that type. To set all "other"
     * types to a mode, write `StringifyAll:1`, or `StringifyAll:2` (or just `StringifyAll` because
     * `:2` is the default). Using our same example, if we want all other objects to use 1-parameter
     * mode,the full string would then be `Automator:1 TypeLibrary:2 StringifyAll:1`.
     * The logic will be applied to both instances and class objects by comparing the string to
     * either `instance.Base.__Class` or `ClassObj.Prototype.__Class`. The search is case insensitive.
     * `Stringify` searches using this pattern:
     * @example
     * RegExMatch(params.callOwnProps, 'i)(^|(?<=\s))(?<type>' obj is Class
     * ? obj.Prototype.__Class : obj.Base.__Class) ')(?::(?<mode>\d+))?((?=\s)|$)', &match)
     * @
     * @property {Boolean} [returnString] - When true, `Stringify` will return the string in addition
     * to assigning it to the VarRef. When false, the string is only assigned to the VarRef.
     *
     */
    static Call(obj, &str?, options?) {
        static controller, HandleObjects, HandleBuiltins, ErrorAction, builtinsList, CallMapEnum
        , CallOwnProps, stringifyTypeTag := '__StringifyTypeTag', params
        , stringifyTag := '__StringifyTag', stringifyAll
        local props, prop, key, typeStr, ownPropsStr, discardGroup, keys
        , enum := flagEnum := flagAsMap := flag := flagSingleLine := false

        ;@region Init
        if !IsSet(controller) {
            str := '', controller := Stringify.Controller(obj, options??{}, stringifyTag, stringifyTypeTag), params := controller.params
            InSequence := [], HandleObjects := []
            CallMapEnum := CallOwnProps := ErrorAction := HandleBuiltins := stringifyAll := ''

            ;@region HandleObjects
            ; return values: 0 - no change; 1 - break and continue to next obj
            ; 2 - break and get standard placeholder; 3 - break and get duplicate placeholder
            ; 4 - break and recurse into obj
            HandleObjects := []
            if params.printPlaceholders
                returnValue := 2, duplicateReturnValue := 3
            else
                returnValue := duplicateReturnValue := 1
            if params.maxDepth
                HandleObjects.Push(_HandleMaxDepth.Bind(returnValue))
            if params.recursePrevention = 1
                HandleObjects.Push(_RecursePrevention1.Bind(duplicateReturnValue))
            else if params.recursePrevention = 2
                HandleObjects.Push(_RecursePrevention2.Bind(duplicateReturnValue))
            HandleObjects.Push(_IsMapOrArray)
            HandleObjects.Push(_HandleNonIterableValue.Bind(returnValue, Stringify.patternNonIterables))
            _RecursePrevention1(duplicateReturnValue, val) => val.HasOwnProp(stringifyTag) && InStr(controller.active.path, val.%stringifyTag%) ? duplicateReturnValue : 0
            _RecursePrevention2(duplicateReturnValue, val) => val.HasOwnProp(stringifyTag) ? duplicateReturnValue : 0
            ; I put `maxDepth` after `recursePrevention` to provide the opportunity to print a duplicate placeholder
            ; if appropriate, instead of a standard placeholder, if the two conditions ever occur in the same object.
            _HandleMaxDepth(returnValue, *) => controller.depth == params.maxDepth ? returnValue : 0
            _IsMapOrArray(val) => RegExMatch(Type(val), '\bMap\b|\bArray\b') ? 4 : 0 ; returning 4 is only valid if this comes after `maxDepth` and `recursePrevention`
            _HandleNonIterableValue(returnValue, pattern, val) {
                if RegExMatch(Type(val), pattern) || (!params.propsList
                || !params.propsList.Has(Type(val))) && !ObjOwnPropCount(val)
                    return returnValue
            }
            ;@endregion

            ;@region ErrorAction
            if params.printErrors {
                if params.printErrors is String
                    ErrorAction := _ProcessErrorLimited.Bind(RegExReplace(params.printErrors, 'i)[^MLWEFLST]', ''))
                else
                    ErrorAction := _ProccessErrorAll
            } else if params.throwErrors
                ErrorAction := _ThrowError

            _ThrowError(err) {
                throw err
            }
            _ProccessErrorAll(err) {
                return (
                    'Type: ' Type(err) '`t'
                    'Message: ' err.message '`t'
                    'What: ' err.What '`t'
                    (err.Extra ? 'Extra: ' err.Extra '`t' : '')
                    'File: ' err.File '`t'
                    'Line: ' err.Line '`t'
                    'Stack: ' err.Stack
                )
            }
            _ProcessErrorLimited(param, err) {
                local str := ''
                for char in StrSplit(param)
                    str .= _GetStr(char) '`t'
                return Trim(str, '`t')
                _GetStr(char) {
                    switch char {
                        case 'M':
                            return 'Message: ' err.Message
                        case 'W':
                            return 'What: ' err.What
                        case 'E':
                            return 'Extra: ' err.Extra
                        case 'F':
                            return 'File: ' err.File
                        case 'L':
                            return 'Line: ' err.Line
                        case 'S':
                            return 'Stack: ' err.Stack
                        case 'T':
                            return 'Type: ' Type(err)
                    }
                }
            }
            ;@endregion

            ;@region OwnProps
            if params.ignoreProps {
                if IsObject(params.ignoreProps) {
                    if not params.ignoreProps is Array
                        throw TypeError('``ignoreProps`` must be either a string or array.', -2, 'Type: ' Type(params.ignoreProps))
                } else
                    params.ignoreProps := [params.ignoreProps]
            } else
                params.ignoreProps := []
            if params.callOwnProps is String {
                if RegExMatch(params.callOwnProps, 'i)(^|(?<=\s))(?<type>StringifyAll)(?::(?<mode>\d+))?((?=\s)|$)', &match)
                    stringifyAll := match['mode'] && match['mode'] == '1' ? 1 : 2
                else
                    stringifyAll := false
                CallOwnProps := _ParseTypeOwnProps.Bind(_CallOwnProps1.Bind(params.ignoreProps, '')
                , _CallOwnProps2.Bind(params.ignoreProps), stringifyAll)
            } else {
                if params.callOwnProps = 1 || (params.propsList && params.propsList.Has(Type(obj)))
                    CallOwnProps := _CallOwnProps1.Bind(params.ignoreProps, '')
                else if params.callOwnProps = 2
                    CallOwnProps := _CallOwnProps2.Bind(params.ignoreProps)
                else
                    throw ValueError('``callOwnProps`` must be either a string, ``0``/``false``,'
                    ' ``1``/``true``, or ``2``.', -1, 'Type: ' Type(params.callOwnProps))
            }

            _SetValueInternal1(&prop, val, &flagEmpty, &SetValue) {
                _Open('{'), flagEmpty := false
                if controller.active.typecode != 'O'
                    controller.active.flagOwnProps := true
                SetValue := _SetValueInternal3, _SetValueInternal2(&prop, val)
            }
            _SetValueInternal2(&prop, val, *) {
                str .= '"' prop '": '
                if IsObject(val)
                    controller.In(val, prop), Stringify(val, &str)
                else
                    _SetVal(&val)
            }
            _SetValueInternal3(&prop, val, *) {
                str .= ',' controller.newline controller.indent '"' prop '": '
                if IsObject(val)
                    controller.In(val, prop), Stringify(val, &str)
                else
                    _SetVal(&val)
            }
            _ParseTypeOwnProps(OP1, OP2, stringifyAll) {
                static param := params.callOwnProps
                if RegExMatch(param,  'i)(^|(?<=\s))(?<type>' (obj is Class
                ? obj.Prototype.__Class : obj.Base.__Class) ')(?::(?<mode>\d+))?((?=\s)|$)', &match)
                    match['mode'] && match['mode'] == '1' ? OP1() : OP2()
                else if stringifyAll == 1
                    OP1()
                else if stringifyAll == 2
                    OP2()
            }
            _CallOwnProps1(listIgnoreProps, propsList, obj) {
                local flagComma := 0, flagIgnore := false, flagEmpty := true, SetValue := _SetValueInternal1
                for prop in obj.OwnProps()
                    _Process(&prop)
                if propsList {
                    for prop in propsList
                        _Process(&prop)
                }

                if flagEmpty
                    str .= '{}'
                else if controller.active.flagOwnProps
                    str .= ',' controller.newline controller.indent '"' _GetItemPropName(controller.active.typecode) '": '
                else
                    _Close('}')

                _Process(&prop) {
                    if prop == 'prop1'
                        sleep 1
                    if obj.HasMethod(prop) || prop == stringifyTag
                        return
                    for ignoreProp in listIgnoreProps {
                        if (SubStr(ignoreProp, 1, 2) == '$.' && controller.active.fullname '.' prop == ignoreProp)
                        || RegExMatch(prop, ignoreProp) {
                            flagIgnore := true
                            break
                        }
                    }
                    if flagIgnore {
                        flagIgnore := false
                        return
                    }
                    result := Stringify.TryProp(obj, &prop, &val)
                    if result == 5 {
                        if ErrorAction
                            val := ErrorAction(val)
                        else
                            return
                    }
                    if IsObject(val) {
                        for fn in HandleObjects {
                            if result := fn(val)
                                break
                        }
                        if result {
                            switch result {
                                case 1:
                                    return
                                case 2:
                                    val := Stringify.GetTypeString(val)
                                case 3:
                                    val := '{' val.%stringifyTag% '}'
                            }
                        }
                    }
                    SetValue(&prop, val, &flagEmpty, &SetValue)
                }
            }
            _CallOwnProps2(listIgnoreProps, obj) {
                local flagIgnore := false, flagEmpty := true, SetValue := _SetValueInternal1
                for prop, val in obj.OwnProps() {
                    if prop == stringifyTag
                        continue
                    if prop == 'prop1'
                        sleep 1
                    for ignoreProp in listIgnoreProps {
                        if (SubStr(ignoreProp, 1, 2) == '$.' && controller.active.fullname '.' prop == ignoreProp)
                        || RegExMatch(prop, ignoreProp) {
                            flagIgnore := true
                            break
                        }
                    }
                    if flagIgnore {
                        flagIgnore := false
                        continue
                    }
                    if IsObject(val) {
                        for fn in HandleObjects {
                            if result := fn(val)
                                break
                        }
                        if result {
                            switch result {
                                case 1:
                                    continue
                                case 2:
                                    val := Stringify.GetTypeString(val)
                                case 3:
                                    val := '{' val.%stringifyTag% '}'
                            }
                        }
                    }
                    SetValue(&prop, val, &flagEmpty, &SetValue)
                }
                if flagEmpty
                    str .= '{}'
                else if controller.active.flagOwnProps
                    str .= ',' controller.newline controller.indent '"' _GetItemPropName(controller.active.typecode) '": '
                else
                    _Close('}')
            }
            ;@endregion

            ;@region Array
            CallArrayEnum(obj) {
                local i := 0, HandleComma := _HandleComma1
                if !obj.length {
                    str .= '[]'
                    return
                }
                _Open('[')
                while ++i <= obj.length {
                    if obj.Has(i) {
                        try
                            val := obj[i]
                        catch Error as err {
                            if ErrorAction
                                val := ErrorAction(val)
                            else
                                continue
                        }
                        if IsObject(val) {
                            for fn in HandleObjects {
                                if result := fn(val)
                                    break
                            }
                            if result {
                                switch result {
                                    case 1:
                                        continue
                                    case 2:
                                        val := Stringify.GetTypeString(val)
                                    case 3:
                                        val := '{' val.%stringifyTag% '}'
                                }
                            }
                        }
                    } else
                        val := params.unsetArrayItem
                    if IsObject(val)
                        HandleComma(), controller.In(val, i), Stringify(val, &str)
                    else
                        HandleComma(), _SetVal(&val)
                }
                _Close(']')

                _HandleComma1() {
                    HandleComma := _HandleComma2
                }
                _HandleComma2() {
                    str .= ',' controller.newline controller.indent
                }
            }
            ;@endregion

            ;@region Map
            if params.ignoreKeys {
                if IsObject(params.ignoreKeys) {
                    if not params.ignoreKeys is Array
                        throw TypeError('``ignoreKeys`` must be either a string or array.', -2, 'Type: ' Type(params.ignoreKeys))
                } else
                    params.ignoreKeys := [params.ignoreKeys]
            } else
                params.ignoreKeys := []
            CallMapEnum := _CallMapEnum.Bind(params.ignoreKeys)
            _CallMapEnum(listIgnoreKeys, obj) {
                local flagIgnore := false, flagNlCharLimitMapItems := false, HandleComma := _HandleComma1, flagEmpty := true
                if !obj.Capacity {
                    str .= '[[]]'
                    return
                }
                for key, val in obj {
                    if IsObject(key)
                        continue
                    if listIgnoreKeys {
                        for ignoreKey in listIgnoreKeys {
                            if (SubStr(ignoreKey, 1, 2) == '$.' && controller.active.fullname '["' key '"]' == ignoreKey) || RegExMatch(key, ignoreKey) {
                                flagIgnore := true
                                break
                            }
                        }
                        if flagIgnore {
                            flagIgnore := false
                            continue
                        }
                    }
                    if IsObject(val) {
                        for fn in HandleObjects {
                            if result := fn(val)
                                break
                        }
                        if result {
                            switch result {
                                case 1:
                                    continue
                                case 2:
                                    val := Stringify.GetTypeString(val)
                                case 3:
                                    val := '{' val.%stringifyTag% '}'
                            }
                        }
                    }
                    HandleComma(), controller.currentIndent++
                    if IsObject(val)
                        controller.In(val, key)
                    if !IsObject(val) && params.nlCharLimitMapItems && StrLen(key) + StrLen(val) < params.nlCharLimitMapItems
                        flagNlCharLimitMapItems := true, str .= '['
                    else
                        str .= '[' controller.newline controller.indent, flagNlCharLimitMapItems := false
                    _SetVal(&key, params.quoteNumericKeys)
                    if flagNlCharLimitMapItems
                        str .= ','
                    else
                        str .= ',' controller.newline controller.indent
                    if IsObject(val)
                        Stringify(val, &str)
                    else
                        _SetVal(&val)
                    controller.currentIndent--
                    if (IsObject(val) && params.nlDepthLimit && controller.depth == params.nlDepthLimit) || flagNlCharLimitMapItems
                        str .= ']'
                    else
                        str .= controller.newline controller.indent ']'
                }
                if flagEmpty
                    str .= '[[]]'
                else
                    _Close(']')

                _HandleComma1() {
                    _Open('['), HandleComma := _HandleComma2, flagEmpty := false
                }
                _HandleComma2() {
                    str .= ',' controller.newline controller.indent
                }
            }
            ;@endregion

        }
        ;@endregion
        

        ;@region Core
        switch Type(obj) {
            case 'Array':
                if params.callOwnProps && ObjOwnPropCount(obj) > 1
                    CallOwnProps(obj)
                CallArrayEnum(obj)
            case 'Map':
                if params.callOwnProps && ObjOwnPropCount(obj) > 1
                    CallOwnProps(obj)
                CallMapEnum(obj)
            default:
                if params.callOwnProps {
                    if params.propsList && params.propsList.Has(Type(obj))
                        _CallOwnProps1(params.ignoreProps, params.propsList[Type(obj)], obj)
                    else
                        CallOwnProps(obj)
                }

        }
        
        if controller.active.flagOwnProps
            _CloseFromFlagOwnProps()
        if controller.Out(obj) {
            controller := unset
            A_Clipboard := str
            if params.returnString
                return str
        }
        ;@endregion



        ;@region Setters
        _Open(bracket) {
            controller.currentIndent++, controller.ToggleSingleLineOn(StrLen(str))
            str .= bracket controller.newline controller.indent
        }
        _Close(bracket) {
            controller.currentIndent--
            str .= controller.newline controller.indent bracket
            _SetSingleLine(controller.ToggleSingleLineOff(StrLen(str)))
        }
        _CloseFromFlagOwnProps() {
            controller.currentIndent--
            result := controller.ToggleSingleLineOff(StrLen(str))
            _SetSingleLine(result)
            str .= controller.newline controller.indent '}'
        }
        _GetItemPropName(typecode) {
            switch typecode {
                case 'A':
                    return params.itemContainerArray
                case 'M':
                    return params.itemContainerMap
            }
        }
        _SetVal(&val, quoteNumbers := false) {
            local pos, match
            if val is Number {
                str .= quoteNumbers ? '"' val '"' : val
                return
            }
            val := StrReplace(val, '\', '\\')
            if params.escapeNL
                val := RegExReplace(val, '\R', params.escapeNL)
            else
                val := StrReplace(StrReplace(val, '`n', '\n'), '`r', '\r')
            val := StrReplace(StrReplace(val, '"', '\"'), '`t', '\t')
            pos := 0
            while pos := RegExMatch(val,"[^\x00-\x7F]", &match, pos+1)
                val := StrReplace(val, match[0], Format("\u{:04X}", Ord(match[0])))
            str .= '"' val '"'
        }
        _SetSingleLine(result) {
            if result && result.result
                str := RegExReplace(str, '\R *', '',,,result.pos||1)
        }
        ;@endregion
    }

    ;@region Controller

    class Controller {
        static patternRecursePrevention := 'i)(^|(?<=\s))(?<type>{1})(?::(?<mode>\d+))?((?=\s)|$)'
        depth := 0, activeList := [], tags := Map(), params := {}
        currentIndent := 0, recursePrevention := 0, singleLineActive := 0, indentStr := [], root := ''
        uncountedChars := 0, lenContainer := Map(), lenEnumObj := Map(), discarded := [], InSequence := []
        OutSequence := [], TestSequenceProp := [], __functionGroup := Map(), TestSequenceKey := []
        flagFromOwnProps := false
        __New(obj, params, stringifyTag, stringifyTypeTag) {
            params := this.params := Stringify.Params(obj, params)
            this.stringifyTag := stringifyTag, this.stringifyTypeTag := stringifyTypeTag

            t := Type(obj), this.root := obj
            
            this.active := {type: Type(obj), class: t == 'Class' ? obj.Prototype.__Class
            : obj.Base.__Class, path: '', name: '$', fullname: '$', flagOwnProps: false,}
            switch t {
                case 'Array':
                    this.active.typecode := 'A'
                case 'Map':
                    this.active.typecode := 'M'
                default:
                    this.active.typecode := 'O'
            }

            if params.singleLine {
                this.singleLineActive := 1
                this.DefineProp('ToggleSingleLineOn', {Call: (*)=>''})
                this.DefineProp('ToggleSingleLineOff', {Call: (*)=>''})
            } else {
                if params.recursePrevention
                    this.InSequence.Push(_SetTag.Bind(stringifyTag)), obj.DefineProp(stringifyTag, {Value: '$'})
                if params.nlDepthLimit
                    this.InSequence.Push(_HandleNlDepthLimit), this.outSequence.Push(_HandleNlDepthLimitOut)
                this.indentStr.Push(params.indent), this.lenContainer.defaut := this.lenEnumObj.default := 0
                if params.nlCharLimitAll
                    params.nlCharLimitArray := params.nlCharLimitMap := params.nlCharLimitObj := params.nlCharLimitAll
            }
            _SetTag(stringifyTag, val, *) => this.tags.Set(val.%stringifyTag% := this.active.fullname, val)
            _HandleNlDepthLimit(*) {
                if this.depth == this.params.nlDepthLimit
                    this.singleLineActive++
            }
            _HandleNlDepthLimitOut(*) {
                if this.depth == this.params.nlDepthLimit
                    this.singleLineActive--
            }
            if params.printTypeTag
                this.InSequence.Push(_SetTypeTag), _SetTypeTag(obj)
            _SetTypeTag(obj, *) => obj.DefineProp(this.stringifyTypeTag
            , {Value: obj is Class ? 'Class:' obj.Prototype.__Class : 'Instance:' obj.Base.__Class})
        }
        
        In(obj, name) {
            t := Type(obj), name := StrReplace(StrReplace(name, '`r', '``r'), '`n', '``n')
            this.activeList.Push(previous := this.active), this.active := {type: t, name: name,
            path: previous.fullname, flagOwnProps: false}
            switch t {
                case 'Array':
                    this.active.typecode := 'A'
                case 'Map':
                    this.active.typecode := 'M'
                default:
                    this.active.typecode := 'O'
            }
            switch previous.type {
                case 'Array':
                    this.active.fullname := previous.fullname '[' name ']'
                case 'Map':
                    this.active.fullname := previous.fullname '["' name '"]'
                default:
                    this.active.fullname := previous.fullname '.' name
            }
            for fn in this.InSequence
                fn(obj, name)
            this.depth++
        }
        Out(obj) {
            if this.activeList.length
                this.active := this.activeList.Pop()
            if this.depth
                this.depth--
            else
                flagStringificationComplete := true
            for fn in this.OutSequence
                fn(obj)
            if IsSet(flagStringificationComplete) {
                if this.params.deleteTags {
                    for key, obj in this.tags
                        obj.DeleteProp(this.stringifyTag)
                    this.root.DeleteProp(this.stringifyTag)
                }
                return 1
            }
        }
        indent {
            Get {
                if this.singleLineActive || !this.currentIndent
                    return ''
                while this.currentIndent > this.indentStr.length
                    this.indentStr.Push(this.indentStr[-1] this.params.indent)
                this.uncountedChars += StrLen(this.indentStr[this.currentIndent])
                return this.indentStr[this.currentIndent]
            }
        }
        newline {
            Get {
                if this.singleLineActive
                    return ''
                if !IsSet(delta)
                    static delta := StrLen(this.params.newline)
                this.uncountedChars += delta
                return this.params.newline
            }
        }
        ToggleSingleLineOn(len) {
            params := this.params
            switch this.active.typecode {
                case 'O':
                    return _Toggle(params.nlCharLimitObj, params.singleLineObj)
                case 'A':
                    return _Toggle(params.nlCharLimitArray, params.singleLineArray)
                case 'M':
                    return _Toggle(params.nlCharLimitMap, params.singleLineMap)
            }
            _Toggle(charLimit, flagSingleLine) {
                if flagSingleLine
                    this.singleLineActive++
                else if charLimit {
                    this.lenContainer.Set(this.active.fullname, {len: len
                    , uncountedChars: this.uncountedChars, limit: charLimit})
                }
            }
        }
        ToggleSingleLineOff(len) {
            params := this.params
            switch this.active.typecode {
                case 'O':
                    return _Toggle(params.singleLineObj)
                case 'A':
                    return _Toggle(params.singleLineArray)
                case 'M':
                    return _Toggle(params.singleLineMap)
            }
            _Toggle(flagSingleLine) {
                if flagSingleLine
                    this.singleLineActive--
                else if (container := this.lenContainer.Has(this.active.fullname) ? this.lenContainer.Get(this.active.fullname) : '') {
                    if (result := len - container.len - (diff:=this.uncountedChars - container.uncountedChars)) <= container.limit {
                        this.uncountedChars -= diff
                        return {pos: container.len, result:true}
                    }
                }
            }
        }
    }
    ;@endregion

    static GetFuncNames(objects, depth := 0, propName := 'FuncNames') {
        if not objects is Array
            objects := [objects]
        i := -1, _Recurse(objects, depth)
        _Recurse(objects, depth) {
            i++
            for obj in objects {
                obj.DefineProp(propName, {Value: ''})
                for prop in obj.OwnProps() {
                    if RegExMatch(Type(obj.%prop%), 'Func|BoundFunc|Closure|Enumerator')
                        obj.%propName% .= prop ' '
                    else if IsObject(obj.%prop%) && depth && i < depth
                        _Recurse([obj.%prop%], depth)
                }
            }
            i--, obj.%propName% := Trim(obj.%propName%, ' ')
        }
    }
    static GetTypeString(val) {
        return '{' _Type() '}'
        _Type() {
            if val is Class
                return 'Class:' val.prototype.__Class
            if val is ComValue
                return _ComObjType()
            return Type(val)
            ; https://www.autohotkey.com/docs/v2/lib/Type.htm
            _ComObjType() {
                if ComObjType(val) & 0x2000 ; VT_ARRAY
                    return 'ComObjArray' ; ComObjArray.Prototype.__Class
                if ComObjType(val) & 0x4000 ; VT_BYREF
                    return 'ComValueRef' ; ComValueRef.Prototype.__Class
                if (ComObjType(val) = 9 || ComObjType(val) = 13) ; VT_DISPATCH || VT_UNKNOWN
                    && ComObjValue(val) != 0
                {
                    if (comClass := ComObjType(val, 'Class')) != ''
                        return comClass
                    if ComObjType(val) = 9 ; VT_DISPATCH
                        return 'ComObject' ; ComObject.Prototype.__Class
                }
                return 'ComValue' ; ComValue.Prototype.__Class
            }
        }
    }

    ; return values: 0 - no change; 5 - error; 6 - value is an object
    static TryProp(obj, &prop, &val) {
        try
            val := obj.%prop%, result := 0
        catch {
            val := obj.GetOwnPropDesc(prop)
            if val.HasOwnProp('value')
                val := val.value, result := 0
            else {
                if val.HasMethod('Get') && val.Get.MinParams <= 1 {
                    try
                        val := val.Get(), result := 0
                    catch Error as err
                        val := err, result := 5
                } else
                    val := MethodError('Property ``' prop '`` does not have an active ``Get`` method.'), result := 5
            }
        }
        if !result && IsObject(val)
            result := 6
        return result
    }
    static __InheritedProps := Map()
    static GetIf(t, &val) {
        if Stringify.__InheritedProps.Has(t) {
            val := Stringify.__InheritedProps.Get(t)
            return 1
        }
    }
    static GetInheritedPropNames(obj, depth?) {
        if Stringify.__InheritedProps.GetIf(t := Type(obj), &val)
            return val.Clone()
        b := t == 'Class' ? obj.Prototype : obj.Base
        Stringify.__InheritedProps.Set(t, props := Map())
        
        Loop {
            if b is Any || A_Index >= depth + 1
                break
            for prop in b.OwnProps() {
                if !b.HasMethod(prop) && prop != '__Class'
                    props.Push(prop)
            }
            b := %b.Base.__Class%.Prototype
        }
        return props
    }
    static GetControlsList(guiObj) {
        guiObj.GetPos(&x, &y, &w, &h)
        guiObj.pos := 'x:' x ' y:' y ' w:' w ' h:' h
        if guiObj.HasOwnProp('Ctrls')
            throw Error('The object already has a property called ``__Ctrls``.', -1)
        guiObj.DefineProp('__Ctrls', {Value: container := Map()})
        for ctrl in guiObj {
            container.Set(ctrl.Name||ctrl.hwnd, ctrl), ctrl.GetPos(&x, &y, &w, &h)
            ctrl.pos := 'x:' x ' y:' y ' w:' w ' h:' h
        }
    }
}
    ;@endregion

class BuiltIns {


    static Has(key) => this.__Item.Has(key)
    static Get(key) => this.__Item.Get(key)
    static Set(key, value) => this.__Item.Set(key, value)
    static GetGuiPos(ctrl) {
        ctrl.GetPos(&x, &y, &w, &h)
        return Format('x:{} y:{} w:{} h:{}', x, y, w, h)
    }
    /** This outputs a semi-structured list of all viable inherited properties */
    static OutputEntireList(pathOut?, &str?) {
        result := Map(), str := ''
        for key, val in Builtins.__Item {
            result.Set(key, container := Map())
            classObj := val.ClassObj
            str .= '`n' classObj.Prototype.__Class '`n'
            Loop 2 {
                if classObj.Prototype.__Class == 'Object'
                    break
                str .= '`t`t' classObj.Prototype.__Class '`n'
                container.Set('props', props := [], 'methods', methods := [], 'error', errors := [])
                for prop in classObj.Prototype.OwnProps() {
                    if prop == '__Class'
                        continue
                    try {
                        if RegExMatch(t := Type(classObj.Prototype.%prop%), 'Func|BoundFunc|Closure|Enumerator')
                            methods.Push(prop)
                        else
                            props.Push(prop)
                    } catch
                        errors.Push(prop)
                }
                classObj := classObj.Base
                if errors.length {
                    str .= '`t`t`t`t----Errors----`n'
                    for item in errors
                        str .= '`t`t`t`t' item '`n'
                }
                if props.length {
                    str .= '`t`t`t`t----Props----`n'
                    for item in props
                        str .= '`t`t`t`t' item '`n'
                }
            }
            for key, val in container {
                if !val.length
                    container.Delete(key)
            }
        }
        Stringify(result, &str, {printTypeTag: false, nlDepthLimit: 4})
        if IsSet(pathOut) {
            f := FileOpen(pathOut, 'a')
            f.Write(str '`n`n')
            f.Close()
        } else if A_LineFile == A_ScriptFullPath
            A_Clipboard := str, msgbox('done')
    }
    ; Any, ComValue, Number, Integer, Float, and String are excluded from the list.
    ; `includeAll` is assigned the value from `includeBuiltinTypes`, which indicates the depth used.
    static __New() {
        this.__Item := Map()
        this.__Item.CaseSense := false
        
        this.__Item.Set('Object', { ClassObj: Object, name: 'Object' }
            ,  'Array', { ClassObj: Array, name: 'Array' }
            ,  'Buffer', { ClassObj: Buffer, name: 'Buffer' }
            ,  'ClipboardAll', { ClassObj: ClipboardAll, name: 'ClipboardAll' }
            ,  'Class', { ClassObj: Class, name: 'Class' }
            ,  'Error', { ClassObj: Error, name: 'Error' }
            ,  'MemoryError', { ClassObj: MemoryError, name: 'MemoryError' }
            ,  'OSError', { ClassObj: OSError, name: 'OSError' }
            ,  'TargetError', { ClassObj: TargetError, name: 'TargetError' }
            ,  'TimeoutError', { ClassObj: TimeoutError, name: 'TimeoutError' }
            ,  'TypeError', { ClassObj: TypeError, name: 'TypeError' }
            ,  'UnsetError', { ClassObj: UnsetError, name: 'UnsetError' }
            ,  'MemberError', { ClassObj: MemberError, name: 'MemberError' }
            ,  'PropertyError', { ClassObj: PropertyError,name: 'PropertyError' }
            ,  'MethodError', { ClassObj: MethodError, name: 'MethodError' }
            ,  'UnsetItemError', { ClassObj: UnsetItemError, name: 'UnsetItemError' }
            ,  'ValueError', { ClassObj: ValueError, name: 'ValueError' }
            ,  'ZeroDivisionError', { ClassObj: ZeroDivisionError, name: 'ZeroDivisionError' }
            ,  'File', { ClassObj: File, name: 'File' }
            ,  'Func', { ClassObj: Func, name: 'Func' }
            ,  'BoundFunc', { ClassObj: BoundFunc, name: 'BoundFunc' }
            ,  'Closure', { ClassObj: Closure, name: 'Closure' }
            ,  'Enumerator', { ClassObj: Enumerator, name: 'Enumerator' }
            ,  'Gui', { ClassObj: Gui, name: 'Gui' }
            ,  'Gui.Control', { ClassObj: Gui.Control, name: 'Gui.Control' }
            ,  'Gui.ActiveX', { ClassObj: Gui.ActiveX, name: 'Gui.ActiveX' }
            ,  'Gui.Button', { ClassObj: Gui.Button, name: 'Gui.Button' }
            ,  'Gui.CheckBox', { ClassObj: Gui.CheckBox, name: 'Gui.CheckBox' }
            ,  'Gui.Custom', { ClassObj: Gui.Custom, name: 'Gui.Custom' }
            ,  'Gui.DateTime', { ClassObj: Gui.DateTime, name: 'Gui.DateTime' }
            ,  'Gui.Edit', { ClassObj: Gui.Edit, name: 'Gui.Edit' }
            ,  'Gui.GroupBox', { ClassObj: Gui.GroupBox, name: 'Gui.GroupBox' }
            ,  'Gui.Hotkey', { ClassObj: Gui.Hotkey, name: 'Gui.Hotkey' }
            ,  'Gui.Link', { ClassObj: Gui.Link, name: 'Gui.Link' }
            ,  'Gui.ComboBox', { ClassObj: Gui.ComboBox, name: 'Gui.ComboBox' }
            ,  'Gui.ListView', { ClassObj: Gui.ListView, name: 'Gui.ListView' }
            ,  'Gui.MonthCal', { ClassObj: Gui.MonthCal, name: 'Gui.MonthCal' }
            ,  'Gui.Pic', { ClassObj: Gui.Pic, name: 'Gui.Pic' }
            ,  'Gui.Progress', { ClassObj: Gui.Progress, name: 'Gui.Progress' }
            ,  'Gui.Radio', { ClassObj: Gui.Radio, name: 'Gui.Radio' }
            ,  'Gui.Slider', { ClassObj: Gui.Slider, name: 'Gui.Slider' }
            ,  'Gui.StatusBar', { ClassObj: Gui.StatusBar, name: 'Gui.StatusBar' }
            ,  'Gui.Text', { ClassObj: Gui.Text, name: 'Gui.Text' }
            ,  'Gui.TreeView', { ClassObj: Gui.TreeView, name: 'Gui.TreeView' }
            ,  'Gui.UpDown', { ClassObj: Gui.UpDown, name: 'Gui.UpDown' }
            ,  'InputHook', { ClassObj: InputHook, name: 'InputHook' }
            ,  'Map', { ClassObj: Map, name: 'Map' }
            ,  'Menu', { ClassObj: Menu, name: 'Menu' }
            ,  'MenuBar', { ClassObj: MenuBar, name: 'MenuBar' }
            ,  'RegExMatchInfo', { ClassObj: RegExMatchInfo, name: 'RegExMatchInfo' }
        )
    }

    static props := Map(
      'Array', ['__Item', 'Capacity', 'Length']
    , 'Buffer', ['Ptr', 'Size']
    , 'ArrayNoItem', ['Capacity', 'Length']
    , 'Error', ['Message', 'Name', 'Extra', 'File', 'Line', 'Stack']
    , 'File', ['AtEOF', 'Encoding', 'Handle', 'Length', 'Pos']
    , 'Gui', ['__Item', 'BackColor', 'FocusedCtrl', 'Hwnd', 'MarginX', 'MarginY', 'MenuBar', 'Name', 'Title']
    , 'GuiNoItem', ['BackColor', 'FocusedCtrl', 'Hwnd', 'MarginX', 'MarginY', 'MenuBar', 'Name', 'Title']
    , 'Gui.Control', ['ClassNN', 'Enabled', 'Focused', 'Hwnd', 'Name', 'Text', 'Type', 'Value', 'Visible']
    , 'InputHook', ['BackspaceIsUndo', 'CaseSensitive', 'EndKey', 'EndMods', 'EndReason', 'FindAnywhere'
      , 'InProgress', 'Input', 'Match', 'MinSendLevel', 'NotifyNonText', 'OnChar', 'OnEnd', 'OnKeyDown'
      , 'OnKeyUp', 'Timeout', 'VisibleNonText', 'VisibleText']
    , 'Map', ['__Item', 'Capacity', 'CaseSense', 'Count']
    , 'MapNoItem', ['Capacity', 'CaseSense', 'Count']
    , 'Menu', ['ClickCount', 'Default', 'Handle']
    , 'MenuBar', ['ClickCount', 'Default', 'Handle']
    , 'RegExMatchInfo', ['__Item', 'Count', 'Len', 'Mark', 'Name', 'Pos']
    , 'RegExMatchInfoNoItem', ['Count', 'Len', 'Mark', 'Name', 'Pos']
    )

    static guiControls := Map(
          'Gui', Builtins.props['GuiNoItem']
        , 'Gui.ActiveX', Builtins.props['Gui.Control'], 'Gui.Button', Builtins.props['Gui.Control']
        , 'Gui.CheckBox', Builtins.props['Gui.Control'], 'Gui.Custom', Builtins.props['Gui.Control']
        , 'Gui.DateTime', Builtins.props['Gui.Control'], 'Gui.Edit', Builtins.props['Gui.Control']
        , 'Gui.GroupBox', Builtins.props['Gui.Control'], 'Gui.Hotkey', Builtins.props['Gui.Control']
        , 'Gui.Link', Builtins.props['Gui.Control'], 'Gui.ComboBox', Builtins.props['Gui.Control']
        , 'Gui.ListView', Builtins.props['Gui.Control'], 'Gui.MonthCal', Builtins.props['Gui.Control']
        , 'Gui.Pic', Builtins.props['Gui.Control'], 'Gui.Progress', Builtins.props['Gui.Control']
        , 'Gui.Radio', Builtins.props['Gui.Control'], 'Gui.Slider', Builtins.props['Gui.Control']
        , 'Gui.StatusBar', Builtins.props['Gui.Control'], 'Gui.Text', Builtins.props['Gui.Control']
        , 'Gui.TreeView', Builtins.props['Gui.Control'], 'Gui.UpDown', Builtins.props['Gui.Control']
    )
}
