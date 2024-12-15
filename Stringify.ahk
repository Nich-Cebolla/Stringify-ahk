

#Include *i StringifyConfig.ahk

class Stringify {
    static params := {
       enumAsMap: false
      , escapeNL: ''
      , hideErrors: false
      , ignore: []
      , indent: '`s`s`s`s'
      , itemContainerArray: '__ArrayItem'
      , itemContainerEnum: '__EnumItem'
      , itemContainerMap: '__MapItem'
      , maxDepth: 0
      , newline: '`n'
      , newlineDepthLimit: 0
      , nlCharLimitArray: 0
      , nlCharLimitMap: 0
      , nlCharLimitObj: 0
      , printFuncPlaceholders: false
      , quoteNumbersAsKey: true
      , recursePrevention: 1
      , singleLineArray: false
      , singleLineMap: false
      , singleLineObj: false
      , useEnum: true
      , useOwnProps: true
    }
    

    ;@region Call
    /** ### Stringify()
     * Available options to pass in the `params` object. See the StringifyConfig.ahk document or
     * the README.md {@link https://github.com/Nich-Cebolla/Stringify-ahk} document for full details.
     * @param {Boolean} [enumAsMap] - When true, all values obtained using `__Enum()` are assumed to belong to a map object.
     * @param {String} [escapeNL] - The literal string of characters to replace matches with '\R.
     * @param {Boolean} [hideErrors] - When true, error text is not printed within the JSON.
     * @param {Array|String} [ignore] - A string or array of strings containing property names / object paths that will not be stringified.
     * @param {String} [indent] - The literal string to use as indentation.
     * @param {String} [itemContainerArray] - The name given to the faux array container.
     * @param {String} [itemContainerEnum] - The name given to the faux enum container.
     * @param {String} [itemContainerMap] - The name given to the faux map container.
     * @param {Number} [maxDepth] - The maximum depth that will be recursed into an stringified.
     * @param {String} [newline] - The literal string used for new lines.
     * @param {Integer} [newlineDepthLimit] - The maximum depth at which newlines will be printed in the JSON string.
     * @param {Integer} [nlCharLimitArray] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @param {Integer} [nlCharLimitMap] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @param {Integer} [nlCharLimitObj] - When an object's stringification is complete, if the length
     * of the object's string representation is under this number, it is condensed to one line.
     * @param {Boolean} [printFuncPlaceholders] - When true, functions are represented in the JSON string
     * as "{Func}", "{BoundFunc}", or "{Closure}".
     * @param {Boolean} [quoteNumbersAsKey] - Quotes numbers when used as a map key.
     * @param {Integer|String} [recursePrevention] - Valid values are: 0 or false - no protection
     * 1 or 'Recursion' - properties that have values that are a parent object are not recurse into.
     * 2 or 'duplicate' - all objects are stringified a maximum of 1 time.
     * @param {Boolean} [singleLineArray] - All arrays are condensed to a single line.
     * @param {Boolean} [singleLineMap] - All maps are condensed to a single line.
     * @param {Boolean} [singleLineObj] - All objects are condensed to a single line.
     * @param {Boolean} [useEnum] - Iterate all object's `__Enum()` method. When false, maps and arrays
     * are still iterated using their basic `__Enum()` method.
     * @param {Boolean} [useOwnProps] - Iterate all objects own properties. When false, objects are
     * still iterated using their `OwnProps()` method.
     * @returns {String}
     */
    static Call(obj, &str,  params?) {
        static tracker, opt
        local props, prop, key, val, typeStr, ownPropsStr, discardGroup, keys
        , enum := flagEnum := flagAsMap := flag := flagOwnProps := flagSingleLine := false

        if !IsSet(tracker) {
            if !IsObject(obj)
                throw TypeError('A non-object value was passed to the function.', -1, 'Type: ' Type(obj))
            tracker := Stringify.Tracker(obj, params??unset), str := '', opt := tracker.opt
        }


        ;@region Core

        switch Type(obj) {
            case 'Map':
                _MapProcess_()
            case 'Array':
                _OwnProps_(true, 'A')
                if obj.length {
                    flag := 0, tracker.ToggleSingleLine(true, 'A', StrLen(str)), _Open_(&str, '[')
                    for item in obj {
                        if tracker.CheckIgnore('#' A_Index)
                            return
                        _HandleNewItem_(&str, &flag), _Process_(obj, &str, item??'""', '#' A_Index)
                    }
                    _Close_(&str, ']')
                    _SetSingleLine_(tracker.ToggleSingleLine(false, 'A', StrLen(str)))
                } else
                    str .= '[]'
                _OwnProps_(false, 'A')
            default:
                try
                    enum := (obj.HasMethod('__Enum') ? true : obj.HasMethod('OwnProps') ? 'OwnProps' : false)
                catch Error as err
                    str .= _GetTypeString_(obj, err)
                if enum == 'OwnProps'
                    _Open_(&str, '{'), _OwnProps_(true, 'O'), _Close_(&str, '}')
                else if enum && opt.useEnum {
                    _OwnProps_(true, 'E'), flagEnum := 0, keys := []
                    try {
                        for key, val in obj {
                            if tracker.CheckIgnore(key)
                                continue
                            if IsObject(key) {
                                tracker.Discard({key:key, val:val, index:A_Index}, &discardGroup)
                                continue
                            }
                            if RegExMatch(key, '^[^a-zA-Z_]|[^\w\d_]') {
                                flagAsMap := true
                                continue
                            }
                            flagEnum := 1, keys.Push(key)
                        }
                    } catch Error as err
                        str .= _GetTypeString_(obj, err), flagEnum := 1
                    if !IsSet(err) && (flagAsMap || opt.enumAsMap)
                        _MapProcess_(), _Close_(&str, '}'), flagEnum := 1
                    else if !IsSet(err) && flagEnum  {
                        tracker.ToggleSingleLine(true, 'O', StrLen(str)), _Open_(&str, '{'), flag := 0
                        for key, val in obj {
                            if tracker.CheckIgnore(key)
                                continue
                            if IsObject(val) && RegExMatch(Type(val), 'Func|BoundFunc|Closure') && !opt.printFuncPlaceholders
                                continue
                            _HandleNewItem_(&str, &flag), str .= '"' key '": ', _Process_(obj, &str, val, key)
                        }
                        _Close_(&str, '}'), _SetSingleLine_(tracker.ToggleSingleLine(false, 'O', StrLen(str)))
                    } else if !flagEnum && !IsSet(err)
                        str .= _GetTypeString_(obj), _Close_(&str, '}')
                    if flagEnum
                        _OwnProps_(false, 'E')
                }
        }
        if tracker.Out(str)
            tracker := unset, opt := unset
        ;@endregion



        ;@region OwnProps

        _PrepareOwnProps_(&str, &flagOwnProps, itemName?, noOpen := false) {
            if _EnumOwnProps_(&ownPropsStr, &len, noOpen) {
                flagOwnProps := true
                if IsSet(itemName)
                    str .= ownPropsStr ',' tracker.newline tracker.indent '"' _GetItemPropName_(itemName) '": '
                else
                    str .= ownPropsStr
            } else
                flagOwnProps := false
        }
        _OwnProps_(start, whichObj) {
            if whichObj != 'O' && !opt.useOwnProps
                return
            if start {
                tracker.ToggleSingleLine(true, whichObj == 'E' ? 'E' : 'O', StrLen(str))
                _PrepareOwnProps_(&str, &flagOwnProps, _ItemName_()||unset, whichObj == 'O')
            } else {
                _SetSingleLine_(tracker.ToggleSingleLine(false, whichObj == 'E' ? 'E' : 'O', StrLen(str)))
                if flagOwnProps && whichObj != 'O'
                    _Close_(&str, '}'), flagOwnProps := false
            }
            _ItemName_() {
                switch whichObj {
                    case 'E':
                        return opt.itemContainerEnum
                    case 'M':
                        return opt.itemContainerMap
                    case 'A':
                        return opt.itemContainerArray
                }
            }
        }
        _EnumOwnProps_(&ownPropsStr, &len, noOpen) {
            local flag := 0, props := [], discardGroup, flagDiscarded
            try {
                for prop in obj.OwnProps() {
                    if tracker.CheckIgnore(prop)
                        continue
                    try
                        val := obj.%prop%, props.Push(prop)
                    catch Error as err
                        tracker.Discard({prop:prop, err:err, obj:obj}, &discardGroup)
                }
            }
            if props.length {
                ownPropsStr := ''
                if !noOpen
                    _Open_(&ownPropsStr, '{')
                for prop in props {
                    if IsObject(obj.%prop%) && RegExMatch(Type(obj.%prop%), 'Func|BoundFunc|Closure') && !opt.printFuncPlaceholders
                        continue
                    _HandleNewItem_(&ownPropsStr, &flag), ownPropsStr .= '"' prop '": ', flagDiscarded := false
                    if IsSet(discardGroup) {
                        for item in tracker.discarded[discardGroup] {
                            if item.prop == prop {
                                ownPropsStr .= _GetTypeString_(obj, item.err, true), flagDiscarded := true
                                break
                            }
                        }
                    }
                    if !flagDiscarded
                        _Process_(obj, &ownPropsStr, obj.%prop%, prop)
                }
            }
            return props.length
        }
        ;@endregion




        ;@region Map

        _MapProcess_() {
            local isEmpty := 1, flag
            _OwnProps_(true, 'M')
            for key, val in obj {
                if tracker.CheckIgnore(key)
                    continue
                isEmpty := 0
                break
            }
            if isEmpty
                str .= '[]'
            else {
                tracker.ToggleSingleLine(true, 'M', StrLen(str)), _Open_(&str, '['), flag := 0
                for key, val in obj {
                    if IsObject(val) && RegExMatch(Type(val), 'Func|BoundFunc|Closure') && !opt.printFuncPlaceholders
                        continue
                    if IsObject(key)
                        key := '"{' _GetTypeString_(key) '}"'
                    if tracker.CheckIgnore(key)
                        continue
                    _HandleNewItem_(&str, &flag), _Open_(&str, '['), _SetVal_(key, &str, opt.quoteNumbersAsKey), str .= ',' tracker.newline tracker.indent
                    _Process_(obj, &str, val, key), _Close_(&str, ']')
                }
                _Close_(&str, ']'), _SetSingleLine_(tracker.ToggleSingleLine(false, 'M', StrLen(str))), _OwnProps_(false, 'M')
            }
        }
        ;@endregion




        ;@region Process

        _Process_(obj, &str, val, name?) {
            if IsObject(val) {
                if opt.maxDepth && tracker.depth == opt.maxDepth
                    str .= _GetTypeString_(val)
                else
                    _Stringify_(val, &str, name)
            } else
                _SetVal_(val, &str)
        }
        _Stringify_(obj, &str, key) {
            if Type(obj) == 'ComValue' || Type(obj) == 'Func' || Type(obj) == 'BoundFunc' || Type(obj) == 'Closure' {
                str .= _GetTypeString_(obj)
                return
            }
            if tracker.In(obj, key) {
                str .= '"{' obj.__StringifyTag '}"'
                    return
            }
            Stringify(obj, &str)
        }
        _HandleNewItem_(&str, &flag) {
            if flag
                str .= ',' tracker.newline tracker.indent
            else
                flag := 1
        }
        ;@endregion



        ;@region Setters

        _GetTypeString_(obj, err?, noQuotes := false) {
            local typeStr, errStr
            if IsSet(err) && !opt.hideErrors
                errStr := '', _SetVal_(_FormatError_(err), &errStr, , true), typeStr := '{' _Type_() '} :: Error: ' errStr
            else
                typeStr := '{' _Type_() '}'
            return noQuotes ? typeStr : '"' typeStr '"'

            _Type_() {
                if Type(obj) == 'Class'
                    return 'Class:' obj.prototype.__Class
                if Type(obj) == 'ComValue'
                    return _ComObjType_(obj)
                return Type(obj)
                ; https://www.autohotkey.com/docs/v2/lib/Type.htm
                _ComObjType_(value) {
                    if ComObjType(obj) & 0x2000 ; VT_ARRAY
                        return 'ComObjArray' ; ComObjArray.Prototype.__Class
                    if ComObjType(obj) & 0x4000 ; VT_BYREF
                        return 'ComValueRef' ; ComValueRef.Prototype.__Class
                    if (ComObjType(obj) = 9 || ComObjType(obj) = 13) ; VT_DISPATCH || VT_UNKNOWN
                        && ComObjValue(obj) != 0
                    {
                        if (comClass := ComObjType(obj, 'Class')) != ''
                            return comClass
                        if ComObjType(obj) = 9 ; VT_DISPATCH
                            return 'ComObject' ; ComObject.Prototype.__Class
                    }
                    return 'ComValue' ; ComValue.Prototype.__Class
                }
            }
        }
        _Open_(&str, bracket) {
            tracker.currentIndent++, str .= bracket tracker.newline tracker.indent
        }
        _Close_(&str, bracket) {
            tracker.currentIndent--, str .= tracker.newline tracker.indent bracket
        }
        _GetItemPropName_(itemPropName) {
            while obj.HasOwnProp(itemPropName)
                itemPropName := itemPropName '_'
            return itemPropName
        }
        _SetVal_(val, &str, quoteNumbers := false, noQuotes := false) {
            local pos, match
            if val is Number {
                str .= quoteNumbers ? '"' val '"' : val
                return
            }
            val := StrReplace(val, '\', '\\')
            if opt.escapeNL
                val := RegExReplace(val, '\R', opt.escapeNL)
            else
                val := StrReplace(StrReplace(val, '`n', '\n'), '`r', '\r')
            val := StrReplace(StrReplace(val, '"', '\"'), '`t', '\t')
            pos := 0
            while pos := RegExMatch(val,"[^\x00-\x7F]", &match, pos+1)
                val := StrReplace(val, match[0], Format("\u{:04X}", Ord(match[0])))
            str .= noQuotes ? val :  '"' val '"'
        }
        _FormatError_(err) {
            return (
                'Type: ' Type(err) tracker.newline
                'Message: ' err.message tracker.newline
                'What: ' err.What tracker.newline
                (err.Extra ? 'Extra: ' err.Extra tracker.newline : '')
                'File: ' err.File tracker.newline
                'Line: ' err.Line tracker.newline
                'Stack: ' err.Stack
            )
        }
        _SetSingleLine_(result) {
            if result && result.result
                str := RegExReplace(str, '\R *', '',,,result.pos||1)
        }
        ;@endregion
    }

    ;@region Tracker

    class Tracker {
        depth := 0, activeList := [], active := '$', depthLimitPivot := '', tags := Map(), opt := {}
        currentIndent := 0, recursePrevention := 0, singleLineActive := 0, indentStr := [], parent := ''
        uncountedChars := 0, lenPrimary := Map(), lenEnumObj := Map(), discarded := []
        __New(obj, params?) {
            opt := this.opt
            for key in Stringify.params.OwnProps() {
                for item in [params??unset, StringifyConfig??unset, Stringify.params] {
                    if IsSet(item) && item.HasOwnProp(key) {
                        opt.%key% := item.%key%
                        break
                    }
                }
            }
            if IsObject(opt.ignore) {
                if Type(opt.ignore) != 'Array'
                    throw TypeError('``ignore`` must be either a string or array.', -2, 'Type: ' Type(opt.ignore))
            } else
                opt.ignore := [opt.ignore]
            if opt.recursePrevention {
                if !RegExMatch(String(opt.recursePrevention), 'i)(1|recursion)(*MARK:1)|(2|duplicate)(*MARK:2)', &match) {
                    throw ValueError('An invalid value was passed to ``recursePrevention``.'
                    ' Valid values are ``1`` or "Recursion" for recursion prevention (properties'
                    ' with a value that is a parent object will be skipped), or ``2`` or'
                    ' "Duplicate" for duplicate prevention (no objects will be stringified more'
                    ' than once), or ``0`` or ``false`` for no prevention.', -1
                    , 'Value: ' IsObject(opt.recursePrevention) ? Type(opt.recursePrevention) : opt.recursePrevention)
                }
                if obj.HasOwnProp('__StringifyTag')
                    Stringify.Tracker.__ThrowTagError()
                this.recursePrevention := match.mark, obj.__StringifyTag := '$'
            }
            this.parent := obj, this.indentStr.Push(opt.indent), this.lenPrimary.default := this.lenEnumObj.default := 0
            this.DefineProp('__Get', {Call: (self, key, *) => self.opt.HasOwnProp(key) ? self.opt.%key% : ''})
            this.DefineProp('__Set', {Call: ___Set_}), this.ToggleSingleLine(true, 'M', 0)
            ___Set_(self, key, value, *) {
                if this.opt.HasOwnProp(key)
                    this.opt.%key% := value
                else
                    throw PropertyError('The tracker does not have a property named ``' key '``.', -1)
            }
        }
        CheckIgnore(name) {
            if name == '__StringifyTag'
                return 1
            for item in this.ignore {
                if (SubStr(item, 1, 2) == '$.' && this.active '.' name == item) || RegExMatch(name, item)
                    return 1
            }
        }
        In(obj, name) {
            if this.recursePrevention {
                if obj.HasOwnProp('__StringifyTag') {
                    if Type(obj.__StringifyTag) != 'String' || (!this.tags.Has(obj.__StringifyTag) && obj.__StringifyTag != '$')
                        Stringify.Tracker.__ThrowTagError()
                    if this.recursePrevention == 2 || InStr(this.active, obj.__StringifyTag)
                        return 1
                }
                this.tags.Set(obj.__StringifyTag := this.active '.' name, obj)
            }
            this.activeList.Push(this.active), this.active := this.active '.' name
            if this.newlineDepthLimit && this.depth == this.newlineDepthLimit
                this.singleLineActive++, this.depthLimitPivot := this.active
            this.depth++
        }
        Out(str) {
            if this.singleLineActive && this.depthLimitPivot == this.active
                this.depthLimitPivot := '', this.singleLineActive--
            current := this.active, this.active := this.activeList.length ? this.activeList.Pop() : ''
            if !this.depth {
                this.ToggleSingleLine(false, 'O', StrLen(str))
                for key, obj in this.tags
                    obj.DeleteProp('__StringifyTag')
                this.parent.DeleteProp('__StringifyTag')
                return 1
            }
            this.depth--
        }
        indent {
            Get {
                if this.singleLineActive || !this.currentIndent
                    return ''
                while this.currentIndent > this.indentStr.length
                    this.indentStr.Push(this.indentStr[-1] this.opt.indent)
                this.uncountedChars += StrLen(this.indentStr[this.currentIndent])
                return this.indentStr[this.currentIndent]
            }
        }
        newline {
            Get {
                if !IsSet(delta)
                    static delta := StrLen(this.opt.newline)
                if this.singleLineActive
                    return ''
                this.uncountedChars += delta
                return this.opt.newline
            }
        }
        ToggleSingleLine(on, whichObj, len) {
            switch whichObj {
                case 'E', 'O':
                    return _Toggle_(on, this.singleLineObj)
                case 'A':
                    return _Toggle_(on, this.singleLineArray)
                case 'M':
                    return _Toggle_(on, this.singleLineMap)
            }

            _Toggle_(on, flagSingleLine) {
                if on {
                    if flagSingleLine
                        this.singleLineActive++
                    else
                        return _RegisterLen_()
                } else {
                    if flagSingleLine
                        this.singleLineActive--
                    else
                        return _ResolveLen_()
                }
            }
            _RegisterLen_() {
                switch whichObj {
                    case 'E':
                        if this.nlCharLimitObj
                            this.lenEnumObj.Set(this.active, {len: len, uncountedChars: this.uncountedChars, limit: this.nlCharLimitObj})
                    case 'O':
                        _Set_(this.nlCharLimitObj)
                    case 'A':
                        _Set_(this.nlCharLimitArray)
                    case 'M':
                        _Set_(this.nlCharLimitMap)
                }
                _Set_(limit) => limit ? this.lenPrimary.Set(this.active, {len: len, uncountedChars: this.uncountedChars, limit: limit}) : ''
            }
            _ResolveLen_() {
                if (obj := (whichObj == 'E' && this.lenEnumObj.Has(this.active)) ? this.lenEnumObj.Get(this.Active)
                : (whichObj != 'E' && this.lenPrimary.Has(this.active)) ? this.lenPrimary.Get(this.active) : '') {
                    if len - obj.len - (diff:=this.uncountedChars - obj.uncountedChars) < obj.limit {
                        this.uncountedChars -= diff
                        return {pos: obj.len, result:true}
                    }
                }
            }
        }

        Discard(item, &groupNum?) {
            if IsSet(groupNum)
                this.discarded[groupNum].Push(item)
            else
                this.discarded.Push([item]), groupNum := this.discarded.length
        }
    
        static __ThrowTagError() {
            throw ValueError('An object seems to have a property ``__StringifyTag`` that was not'
            ' added by this function. This property name is used for recursion prevention.'
            ' You can disable recursion prevention, or temporarily remove the property from the object.', -2)
        }
    }
    ;@endregion



    ;@region Debug

    ; static debug := false, debugPath := A_ScriptDir '\Debug_out.txt'
    ; , debugPathTracker := A_ScriptDir '\Debug_out_tracker.txt'
    ; , debugPathExtra := A_ScriptDir '\Debug_out_extra.txt'

    ; static __DebugExtra(str) {
    ;     if !Stringify.debug
    ;         return
    ;     if !Stringify.HasOwnProp('_fe')  {
    ;         f := FileOpen(Stringify.debugPathExtra, 'w')
    ;         f.write('')
    ;         f.close()
    ;         Stringify._fe := FileOpen(Stringify.debugPathExtra, 'a')
    ;     }
    ;     Stringify._fe.Write(str '`n`n')
    ; }

    ; static __Debug(str, key, active, fn, ln) {
    ;     if !Stringify.debug
    ;         return
    ;     if !Stringify.HasOwnProp('_f')  {
    ;         f := FileOpen(Stringify.debugPath, 'w')
    ;         f.write('')
    ;         f.close()
    ;         Stringify._f := FileOpen(Stringify.debugPath, 'a')
    ;     }
    ;     Stringify._f.Write(Format('Function: {}   Line: {}`nKey: {}   Active: {}`n{}`n`n', fn, ln, key, active, str))
    ; }

    ; static __DebugTracker(active, str, fn, ln, name, extra?) {
    ;     if !Stringify.debug
    ;         return
    ;     if !Stringify.HasOwnProp('_ft') {
    ;         f := FileOpen(Stringify.debugPathTracker, 'w')
    ;         f.write('')
    ;         f.close()
    ;         Stringify._ft := FileOpen(Stringify.debugPathTracker, 'a')
    ;     }
    ;     split := StrSplit(str, '$')
    ;     writeout := fn ' ' ln '`nCurrent active: ' active '`nActive string:`n', i := 0
    ;     for item in split {
    ;         i++, writeout .= item
    ;         if i >= 20
    ;             writeout .= '`n', i := 0
    ;     }
    ;     writeout .= 'Name: ' name (IsSet(extra) ? '`nExtra: ' extra : '') '`n`n'
    ;     Stringify._ft.Write(writeout)
    ; }
    ;@endregion
}
    ;@endregion

