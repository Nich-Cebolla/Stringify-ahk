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
        static ignoreProps := ''
        static ignoreKeys := ''
        static recursePrevention := 1
        ; Builtins
        static includeBuiltinTypes := false
        static includeBuiltinProps := ''
        static ignoreBuiltinProps := ''
        ; Directs `Stringify` to get properties of Gui objects and Gui.Control objects.
        static includeGui := false

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
        static printFuncPlaceholders := false
        static printPlaceholders := false
        static quoteNumericKeys := true
        static printTypeTag := true
        static itemContainerArray := '__ArrayItem'
        static itemContainerMap := '__MapItem'

        ; Misc options
        static returnString := false
        static deleteTags := true
        
        __New(obj, params) {
            for key, val in Stringify.Params.OwnProps() {
                this.%key% := params.HasOwnProp(key) ? params.%key% : IsSet(StringifyConfig)
                && StringifyConfig.HasOwnProp(key) ? StringifyConfig.%key% : val
            }
        }
    }
    
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
     * 1 or 'Recursion' - properties that have values that are a parent object are not recurse into.
     * 2 or 'duplicate' - all objects are stringified a maximum of 1 time.
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
     * RegExMatch(params.callOwnProps, 'i)(^|(?<=\s))(?<type>' (Type(obj) == 'Class'
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
        local props, prop, key, val, typeStr, ownPropsStr, discardGroup, keys, tempStr
        , enum := flagEnum := flagAsMap := flag := flagSingleLine := false

        ;@region Init
        if !IsSet(controller) {
            if !IsObject(obj)
                throw TypeError('A non-object value was passed to the function.', -1, 'Type: ' Type(obj))
            str := '', controller := Stringify.Controller(obj, options??{}, stringifyTag, stringifyTypeTag), params := controller.params
            InSequence := [], HandleObjects := []
            CallMapEnum := CallOwnProps := ErrorAction := HandleBuiltins := stringifyAll := ''

            ;@region ErrorAction
            if params.printErrors {
                if Type(params.printErrors) == 'String'
                    ErrorAction := _ProcessErrorLimited_.Bind(RegExReplace(params.printErrors, 'i)[^MLWEFLST]', ''))
                else
                    ErrorAction := _ProccessErrorAll_
            }
            _ProccessErrorAll_(err) {
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
            _ProcessErrorLimited_(param, err) {
                local str := ''
                for char in StrSplit(param)
                    str .= _GetStr_(char) '`t'
                return Trim(str, '`t')
                _GetStr_(char) {
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


            ;@region Array
            CallArrayEnum(obj) {
                local flagComma := 0, i := 0
                if !obj.length {
                    str .= '[]'
                    return
                }
                _Open_(controller.active.flagOwnProps||unset)
                while ++i <= obj.length {
                    if !obj.Has(i) {
                        _HandleComma_(), str .= '""'
                        continue
                    }
                    try
                        val := obj[i]
                    catch Error as err {
                        if ErrorAction
                            _HandleComma_(), val := ErrorAction(err), _SetVal_(&val)
                        continue
                    }
                    if IsObject(val) {
                        if result := _HandleObject_(val) {
                            if IsNumber(result)
                                _HandleComma_(), controller.In(val, i), Stringify(val, &str)
                            else
                                _HandleComma_(), _SetVal_(&result)
                        }
                    } else
                        _HandleComma_(), _SetVal_(&val)
                }
                _Close_(controller.active.flagOwnProps||unset)
    
                _HandleComma_() {
                    if flagComma
                        str .= ',' controller.newline controller.indent
                    else
                        flagComma := 1
                }
            }
            ;@endregion

            ;@region Map
            if params.ignoreKeys {
                if IsObject(params.ignoreKeys) {
                    if Type(params.ignoreKeys) != 'Array'
                        throw TypeError('``ignoreKeys`` must be either a string or array.', -2, 'Type: ' Type(params.ignoreKeys))
                } else
                    params.ignoreKeys := [params.ignoreKeys]
                for item in params.ignoreKeys {
                    if Type(item) != 'String'
                        throw TypeError('``ignoreKeys`` must be an array of strings.', -2, 'Type: ' Type(item))
                }
            }
            CallMapEnum := _CallMapEnum_.Bind(params.ignoreKeys)
            _CallMapEnum_(listIgnoreKeys, obj) {
                local flagComma := 0, flagIgnore, keys := Map(), flagNlCharLimitMapItems
                for key in obj {
                    if IsObject(key) && Type(obj) != 'Gui'
                        continue
                    if listIgnoreKeys {
                        flagIgnore := false
                        for ignoreKey in listIgnoreKeys {
                            if (SubStr(ignoreKey, 1, 2) == '$.' && controller.active.fullname '["' key '"]' == ignoreKey) || RegExMatch(key, ignoreKey) {
                                flagIgnore := true
                                break
                            }
                        }
                        if flagIgnore
                            continue
                    }
                    if Type(obj) == 'Gui' {
                        try
                            temp := key.name, val := key, key := temp
                        catch Error as err {
                            if ErrorAction
                                keys.Set(key, ErrorAction(err))
                            continue
                        }
                    } else {
                        try
                            val := obj[key]
                        catch Error as err {
                            if ErrorAction
                                keys.Set(prop, ErrorAction(err))
                            continue
                        }
                    }
                    keys.Set(key, val)
                }
                if !keys.Capacity {
                    str .= '[[]]'
                    return
                }
                _Open_(controller.active.flagOwnProps||unset)
                for key, val in keys {
                    flagNlCharLimitMapItems := false
                    if IsObject(val) {
                        if result := _HandleObject_(val, key, keys) {
                            if !IsNumber(result)
                                val := result
                        } else
                            continue
                    }
                    if flagComma
                        str .= ',' controller.newline controller.indent
                    else
                        flagComma := 1
                    controller.currentIndent++
                    if IsObject(val)
                        controller.In(val, key)
                    if !IsObject(val) && params.nlCharLimitMapItems && StrLen(key) + StrLen(val) < params.nlCharLimitMapItems
                        flagNlCharLimitMapItems := true, str .= '['
                    else
                        str .= '[' controller.newline controller.indent
                    _SetVal_(&key, params.quoteNumericKeys)
                    if flagNlCharLimitMapItems
                        str .= ','
                    else
                        str .= ',' controller.newline controller.indent
                    if IsObject(val)
                        Stringify(val, &str)
                    else
                        _SetVal_(&val)
                    controller.currentIndent--
                    if (IsObject(val) && params.nlDepthLimit && controller.depth == params.nlDepthLimit) || flagNlCharLimitMapItems
                        str .= ']'
                    else
                        str .= controller.newline controller.indent ']'
                }
                _Close_(controller.active.flagOwnProps||unset)
            }
            ;@endregion


            ;@region OwnProps
            if params.callOwnProps {
                builtinsList := BuiltIns(params.includeBuiltinTypes||unset
                , params.includeBuiltinProps||unset, params.ignoreBuiltinProps||unset, params.includeGui)
                HandleBuiltins := _HandleBuiltinsList_
                if params.ignoreProps {
                    if IsObject(params.ignoreProps) {
                        if Type(params.ignoreProps) != 'Array'
                            throw TypeError('``ignoreProps`` must be either a string or array.', -1
                            , 'Type: ' Type(params.ignoreProps))
                    } else
                        params.ignoreProps := [params.ignoreProps]
                    for item in params.ignoreProps {
                        if Type(item) != 'String'
                            throw TypeError('``ignoreProps`` must be an array of strings.', -1, 'Type: ' Type(item))
                    }
                }
                if Type(params.callOwnProps) == 'String' {
                    if RegExMatch(params.callOwnProps, 'i)(^|(?<=\s))(?<type>StringifyAll)(?::(?<mode>\d+))?((?=\s)|$)', &match)
                        stringifyAll := match['mode'] && match['mode'] == '1' ? 1 : 2
                    else
                        stringifyAll := false
                    CallOwnProps := _ParseTypeOwnProps_.Bind(_CallOwnProps1_.Bind(params.ignoreProps)
                    , _CallOwnProps2_.Bind(params.ignoreProps), stringifyAll)
                } else {
                    if params.callOwnProps = 1
                        CallOwnProps := _CallOwnProps1_.Bind(params.ignoreProps)
                    else if params.callOwnProps = 2
                        CallOwnProps := _CallOwnProps2_.Bind(params.ignoreProps)
                    else
                        throw ValueError('``callOwnProps`` must be either a string, ``0``/``false``,'
                        ' ``1``/``true``, or ``2``.', -1, 'Type: ' Type(params.callOwnProps))
                }
            } else {
                if (t := Type(obj)) != 'Array' && t != 'Map'
                    throw TypeError('You called ``Stringify`` with an object, but the option ``callOwnProps``'
                    ' is currently ``false``, which means that ``OwnProps`` will not be iterated.'
                    ' To Stringify an object, set ``OwnProps`` to ``1`` or ``2``.', -1)
                HandleBuiltins := _HandleBuiltinsNoList_
            }
            _ParseTypeOwnProps_(OP1, OP2, stringifyAll, obj) {
                static param := params.callOwnProps
                if RegExMatch(param,  'i)(^|(?<=\s))(?<type>' (Type(obj) == 'Class'
                ? obj.Prototype.__Class : obj.Base.__Class) ')(?::(?<mode>\d+))?((?=\s)|$)', &match)
                    match['mode'] && match['mode'] == '1' ? OP1() : OP2()
                else if stringifyAll == 1
                    OP1()
                else if stringifyAll == 2
                    OP2()
            }
            _CallOwnProps1_(listIgnoreProps, obj, props?) {
                local flagComma := 0, flagIgnore
                if !IsSet(props)
                    props := Map()
                for prop in obj.OwnProps() {
                    if prop == stringifyTag || prop == 'Prototype' || prop == 'Base'
                        continue
                    if listIgnoreProps {
                        flagIgnore := false
                        for ignoreProp in listIgnoreProps {
                            if (SubStr(ignoreProp, 1, 2) == '$.' && controller.active.fullname '.' prop == ignoreProp) || RegExMatch(prop, ignoreProp) {
                                flagIgnore := true
                                break
                            }
                        }
                        if flagIgnore
                            continue
                    }
                    try
                        val := obj.%prop%
                    catch Error as err {
                        if ErrorAction
                            props.Set(prop, ErrorAction(err))
                        continue
                    }
                    props.Set(prop, val)
                }
                _IterateProps_(props, obj)
            }
            _CallOwnProps2_(listIgnoreProps, obj) {
                local props := Map(), flagIgnore
                try {
                    for prop, val in obj.OwnProps() {
                        if prop == stringifyTag || prop == 'Prototype'
                            continue
                        if listIgnoreProps {
                            flagIgnore := false
                            for ignoreProp in listIgnoreProps {
                                if (SubStr(ignoreProp, 1, 2) == '$.' && controller.active.fullname '.' prop == ignoreProp) || RegExMatch(prop, ignoreProp) {
                                    flagIgnore := true
                                    break
                                }
                            }
                            if flagIgnore
                                continue
                        }
                        props.Set(prop, val)
                    }
                } catch Error as err {
                    if controller.active.typecode == 'O'
                        props := Map(), _CallOwnProps1_(params.ignoreProps, obj, props)
                    return
                }
                _IterateProps_(props, obj)
            }
            _IterateProps_(props, obj) {
                local flagComma := 0
                t := controller.active.type
                if builtinsList.Has(t) {
                    for prop in builtinsList.GetList(t) {
                        try
                            val := obj.%prop%
                        catch
                            continue
                        props.Set(prop, val)
                    }
                    if InStr(t, 'Gui') {
                        name := 'pos'
                        while props.Has(name)
                            name := '_' name
                        props.Set(name, Builtins.GetGuiPos(obj))
                    }
                }
                if !props.Capacity {
                    if controller.active.typecode == 'O'
                        str .= '{}'
                    return
                }
                if controller.active.typecode != 'O'
                    controller.active.flagOwnProps := controller.active.typecode, controller.active.typecode := 'O'
                _Open_()
                for prop, val in props {
                    if IsObject(val) {
                        if result := _HandleObject_(val, prop) {
                            if !IsNumber(result)
                                val := result
                        } else
                            continue
                    }
                    if prop == 'prop1'
                        sleep 1
                    if flagComma
                        str .= ',' controller.newline controller.indent
                    else
                        flagComma := 1
                    str .= '"' prop '": '
                    if IsObject(val)
                        controller.In(val, prop), Stringify(val, &str)
                    else
                        _SetVal_(&val)
                }
                if controller.active.flagOwnProps {
                    str .= ',' controller.newline controller.indent '"' _GetItemPropName_(controller.active.flagOwnProps) '": '
                } else
                    _Close_()
            }
            ;@endregion

            ;@region HandleObjects
            _HandleObject_(val, name?, list?) {
                local flagPlaceholder := false
                for fn in HandleObjects {
                    if flagPlaceholder := fn(val)
                        break
                }
                if flagPlaceholder && !params.printPlaceholders
                    return
                if RegExMatch(Type(val), 'Func|BoundFunc|Closure|Enumerator') {
                    if !params.printFuncPlaceholders
                        return
                    flagPlaceholder := 1
                }
                if flagPlaceholder == 1
                    return _GetTypeString_(val)
                else if flagPlaceholder == 2
                    return '{' val.%stringifyTag% '}'
                else
                    return 1
            }
            HandleObjects := [_HandleComValue_, HandleBuiltins]
            _HandleComValue_(val) => Type(val) == 'ComValue'
            _HandleBuiltinsList_(val) {
                t := Type(val)
                if builtinsList.active {
                    if Builtins.Has(t) {
                        if !builtinsList.Has(t) {
                            if !RegExMatch(t, 'Map|Array|Class|Object')
                                return 1
                        }
                    }
                }
            }
            _HandleBuiltinsNoList_(val) => Builtins.Has(Type(val))
            if params.recursePrevention {
                if params.recursePrevention = 2
                    HandleObjects.Push(_RecursePrevention2_)
                else if IsNumber(params.recursePrevention)
                    HandleObjects.Push(_RecursePrevention1_)
                else
                    throw TypeError('``recursePrevention`` must be a number or ``true`` or ``false``.'
                    , -2, 'Type: ' Type(params.recursePrevention))
                controller.InSequence.Push(_SetTag_)
                obj.DefineProp(stringifyTag, {Value: '$'})
            }
            _RecursePrevention2_(val) => val.HasOwnProp(stringifyTag) ? 2 : 0
            _RecursePrevention1_(val) => val.HasOwnProp(stringifyTag) && InStr(controller.active.path
            , val.%stringifyTag%) ? 2 : 0
            _SetTag_(val, *) => controller.tags.Set(val.%stringifyTag% := controller.active.fullname, val)
            if params.maxDepth
                HandleObjects.Push(_HandleMaxDepth_)
            _HandleMaxDepth_(*) => controller.depth == params.maxDepth
            ;@endregion

        }
        ;@endregion
        

        ;@region Core
        if params.callOwnProps
            CallOwnProps(obj)
        switch Type(obj) {
            case 'Array':
                CallArrayEnum(obj)
            case 'Map', 'Gui':
                CallMapEnum(obj)
        }
        
        if controller.active.flagOwnProps
            _Close_()
        if controller.Out(obj) {
            controller := unset
            A_Clipboard := str
            if params.returnString
                return str
        }
        ;@endregion



        ;@region Setters
        _GetTypeString_(val) {
            return '{' _Type_() '}'

            _Type_() {
                if Type(val) == 'Class'
                    return 'Class:' val.prototype.__Class
                if Type(val) == 'ComValue'
                    return _ComObjType_()
                return Type(val)
                ; https://www.autohotkey.com/docs/v2/lib/Type.htm
                _ComObjType_() {
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
        _Open_(typecode?) {
            local temp
            if IsSet(typecode)
                temp := controller.active.typecode, controller.active.typecode := typecode
            controller.currentIndent++, controller.ToggleSingleLineOn(StrLen(str))
            str .= _GetOpenBracket_(controller.active.typecode) controller.newline controller.indent
            if IsSet(typecode)
                controller.active.typecode := temp
        }
        _Close_(typecode?) {
            local temp
            if IsSet(typecode)
                temp := controller.active.typecode, controller.active.typecode := typecode
            controller.currentIndent--
            str .= controller.newline controller.indent _GetCloseBracket_(controller.active.typecode)
            _SetSingleLine_(controller.ToggleSingleLineOff(StrLen(str)))
            if IsSet(typecode)
                controller.active.typecode := temp
        }
        _GetOpenBracket_(typecode) {
            switch typecode {
                case 'A':
                    return '['
                case 'M':
                    return '['
                default:
                    return '{'
            }
        }
        _GetCloseBracket_(typecode) {
            switch typecode {
                case 'A':
                    return ']'
                case 'M':
                    return ']'
                default:
                    return '}'
            }
        }
        _GetItemPropName_(typecode) {
            switch typecode {
                case 'A':
                    itemPropName := params.itemContainerArray
                case 'M':
                    itemPropName := params.itemContainerMap
            }
            while obj.HasOwnProp(itemPropName)
                itemPropName := itemPropName '_'
            return itemPropName
        }
        _SetVal_(&val, quoteNumbers := false) {
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
        _SetSingleLine_(result) {
            A_Clipboard := str
            sleep 1
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
                if params.nlDepthLimit
                    this.InSequence.Push(_HandleNlDepthLimit_), this.outSequence.Push(_HandleNlDepthLimitOut_)
                this.indentStr.Push(params.indent), this.lenContainer.defaut := this.lenEnumObj.default := 0
                if params.nlCharLimitAll
                    params.nlCharLimitArray := params.nlCharLimitMap := params.nlCharLimitObj := params.nlCharLimitAll
            }
            _HandleNlDepthLimit_(*) {
                if this.depth == this.params.nlDepthLimit
                    this.singleLineActive++
            }
            _HandleNlDepthLimitOut_(*) {
                if this.depth == this.params.nlDepthLimit
                    this.singleLineActive--
            }
            if params.printTypeTag
                this.InSequence.Push(_SetTypeTag_), _SetTypeTag_(obj)
            _SetTypeTag_(obj, *) => obj.DefineProp(this.stringifyTypeTag
            , {Value: Type(obj) == 'Class' ? 'Class:' obj.Prototype.__Class : 'Instance:' obj.Base.__Class})
        }
        
        In(obj, name) {
            t := Type(obj), name := StrReplace(StrReplace(name, '`r', '``r'), '`n', '``n')
            this.activeList.Push(previous := this.active), this.active := {type: t, name: name,
            path: previous.fullname, flagOwnProps: false}
            switch t {
                case 'Array':
                    this.active.typecode := 'A'
                case 'Map', 'Gui':
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
                    return _Toggle_(params.nlCharLimitObj, params.singleLineObj)
                case 'A':
                    return _Toggle_(params.nlCharLimitArray, params.singleLineArray)
                case 'M':
                    return _Toggle_(params.nlCharLimitMap, params.singleLineMap)
            }
            _Toggle_(charLimit, flagSingleLine) {
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
                    return _Toggle_(params.singleLineObj)
                case 'A':
                    return _Toggle_(params.singleLineArray)
                case 'M':
                    return _Toggle_(params.singleLineMap)
            }
            _Toggle_(flagSingleLine) {
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
    ; Any, ComValue, Number, Integer, Float, and String are excluded from the list.
    ; `includeAll` is assigned the value from `includeBuiltinTypes`, which indicates the depth used.
    static __New() {
        this.__Item := Map()
        this.__Item.CaseSense := false
        
        this.__Item.Set('Object', { name: 'Object' }
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
    
    Has(t) => this.lists.Has(t) || (this.includeAll && Builtins.Has(t)) || (this.includeGui && InStr(t, 'Gui'))
    Get(t) => this.lists.Get(t)
    Set(t, value) => this.lists.Set(t, value)
    Delete(t) => this.lists.Delete(t)
    __Item[t] {
        Get => this.Get(t)
        Set => this.Set(t, value)
    }

    includeAll := false, active := false, includeGui := false
    __New(includeBuiltinTypes?, includeProps?, ignoreProps?, includeGui := false) {
        validation := 0, this.includeGui := true
        this.lists := Map(), this.lists.casesense := false
        if IsSet(includeBuiltinTypes) {
            if Type(includeBuiltinTypes) == 'String'
                this.SetListTypes(includeBuiltinTypes)
            else
                this.includeAll := includeBuiltinTypes
            validation++
        }
        if IsSet(includeProps)
            this.SetListInludeProps(includeProps), validation++
        if IsSet(ignoreProps)
            this.SetlistIgnoreProps(ignoreProps), validation++
        if validation > 1
            throw ValueError('Only one of the parameters ``includeBuiltinTypes``, ``includeProps``, or'
            ' ``ignoreProps`` can be used at a time.', -2)
        if validation == 1
            this.active := true
    }

    SetListTypes(builtinTypes) {
        for item in StrSplit(RegExReplace(builtinTypes, '\s+', ' '), ' ') {
            if !RegExMatch(item, '^(?<type>[\w.]+)(?::(?<depth>.+))?$', &match)
                throw ValueError('Invalid format for ``includeBuiltinTypes``. The format should be'
                ' ``ObjType:depth', -2, 'Value: ' item)
            if !Builtins.Has(match['type'])
                throw ValueError('Invalid object type in ``includeBuiltinTypes``.', -2, 'Value: '
                match['type'] '`tIn context: ' item)
            this.lists.Set(match['type'], propList := [])
            classObj := Builtins[match['type']].ClassObj
            Loop (match['depth'] ? Number(match['depth']) + 1 : 3) {
                if classObj.Prototype.__Class == 'Any'
                    break
                for prop in classObj.Prototype.OwnProps() {
                    if prop != '__Item'
                        propList.Push(prop)
                }
                classObj := classObj.Base
            }
        }
    }

    SetListInludeProps(includeProps) {
        if InStr(includeProps, '__Item')
            throw ValueError('The property ``__Item`` cannot be used as an option for ``includeBuiltinProps``.', -2)
        for item in StrSplit(RegExReplace(includeProps, '\s+', ' '), ' ') {
            if !RegExMatch(item, '^(?<type>[\w.]+):(?<list>[^:]+)', &match)
                throw ValueError('Invalid format for ``includeBuiltinProps``. The format should be'
                ' ``ObjType:List|Of|Prop|Names', -2, 'Value: ' item)
            if !Builtins.Has(match['type'])
                throw ValueError('Invalid object type in ``includeBuiltinProps``.', -2, 'Value: '
                match['type'] '`tIn context: ' item)
            this.lists.Set(match['type'], StrSplit(match['list'], '|'))
        }
    }

    SetlistIgnoreProps(ignoreProps) {
        for item in StrSplit(RegExReplace(ignoreProps, '\s+', ' '), ' ') {
            if !RegExMatch(item, '^(?<type>[\w.]+):(?<list>[^:]+?)(?::(?<depth>.+))?$', &match)
                throw ValueError('Invalid format for ``ignoreBuiltinProps``. The format should be'
                ' ``ObjType:List|Of|Prop|Names:depth', -2, 'Value: ' item)
            if !Builtins.Has(match['type'])
                throw ValueError('Invalid object type in ``ignoreBuiltinProps``.', -2, 'Value: '
                match['type'] '`tIn context: ' item)
            this.lists.Set(match['type'], propList := [])
            classObj := Builtins[match['type']].ClassObj
            Loop (match['depth'] ? Number(match['depth']) + 1 : 3) {
                if classObj.Prototype.__Class == 'Any'
                    break
                for prop in classObj.Prototype.OwnProps() {
                    if !RegExMatch(prop, match['list']) && prop != '__Item'
                        propList.Push(prop)
                }
                classObj := classObj.Base
            }
        }
    }

    GetList(t) {
        if !this.lists.Has(t) && (this.includeAll || (this.includeGui && InStr(t, 'Gui')))
            this.SetListTypes(t ':' this.includeAll)
        if this.lists.Has(t)
            return this.lists.Get(t)
    }
}
