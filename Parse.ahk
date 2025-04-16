

class Parse {
    ; Options with * are only relevant if the object was stringified with the `Stringify` class by the same author.
    class Params {
        static encoding := ''
        static includePlaceholders := false ;*
        static includeFuncPlaceholders := false ;*
        static restoreDuplicateObjects := false ;*
        static restoreArray := true ;*
        static restoreMap := true ;*
        static restoreClassType := true ;*
        static itemContainerArray := '__ArrayItem' ;*
        static itemContainerMap := '__MapItem' ;*
        static tempPropTag := '__ParseParentProp' ;*
        static ignore := ['__StringifyTag']
        static maxDepth := 0
        static showRestoreClassTypeErrors := false ;*
        static AllNumbersAreString := false
        static NumericKeysAreString := false
        static nullValue := ""
        static ConvertNewline := '`r`n'
        static pattern := {
            quote: '"(?<value>.*?)(?<!\\)(?:\\\\)*"'
            , num: '(?<n>-?\d++(?:\.\d++)?)(?<e>[eE][+-]?\d++)?'
            , prop: '(?:(?<=[\]}{[,\s\r\n])"(?<prop>[\w\d_]+)(?<!\\)(?:\\\\)*":[\r\n\s]*(.))'
            , keyword: 'true|false|null'
            , bracketSquare: '\['
            , bracketCurly: '\{'
            , bracketSquareClose: '\]'
            , bracketCurlyClose: '\}'
        }
        __New(params) {
            for key, val in Parse.Params.OwnProps() {
                this.%key% := params.HasOwnProp(key) ? params.%key% : IsSet(ParseConfig)
                && ParseConfig.HasOwnProp(key) ? ParseConfig.%key% : val
            }
        }
    }

    static patternObjActive := (
        '{1}(?COnBracketCurlyClose)'
        '|{2}(?COnProp)'
    )
    static patternArrActive := (
        '{1}(?COnBracketSquare)'
        '|{2}(?COnBracketCurly)'
        '|{3}(?COnBracketSquareClose)'
        '|{4}(?COnBracketCurlyClose)'
        '|{5}(?COnNumber)'
        '|{6}(?COnQuote)'
        '|{7}(?COnKeyword)'
    )

    static Call(&str?, path?, params?) {
        local OnProp, OnBracketSquareClose, OnBracketCurlyClose, HandleNumber, OnPropOptionFuncs
        , duplicateObjects
        params := Parse.Params(params??{})
        if IsSet(path)
            str := FileRead(path, params.Encoding||unset)
        else if !IsSet(str)
            str := A_Clipboard
        if !str
            throw ValueError('No string or path was provided, and the clipboard does not contain text.', -1)
        ; Prepare input parameters
        depth := [], pos := RegExMatch(str, '[[{]', &match)
        p := params.pattern
        patternObjActive := Format(this.patternObjActive, p.bracketCurlyClose, p.prop)
        patternArrActive := Format(this.patternArrActive, p.bracketSquare, p.bracketCurly
        , p.bracketSquareClose, p.bracketCurlyClose, p.num, p.quote, p.keyword)
        if match[0] == '['
            obj := [], pattern := patternArrActive
        else if match[0] == '{'
            obj := {}, pattern := patternObjActive
        else
            throw ValueError('An opening brace was not found in the string.', -1)
        ; Set functions according to input options
        OnPropOptionFuncs := [], OnPropOptionFuncs.length := 2, GetObjFuncs := []
        if params.restoreDuplicateObjects
            duplicateObjects := [], OnPropOptionFuncs[2] := _HandleValDuplicateObjects_
        else
            OnPropOptionFuncs[2] := _HandleVal_
        if params.includePlaceholders && params.includeFuncPlaceholders
            OnPropOptionFuncs[1] := _OnPropIncludeAllPlaceholders_
        else if params.includePlaceholders
            OnPropOptionFuncs[1] := _OnPropIncludePlaceholders_
        else if params.includeFuncPlaceholders
            OnPropOptionFuncs[1] := _OnPropIncludeFuncPlaceholders_
        else
            OnPropOptionFuncs[1] := _OnProp_
        OnPropShared := Params.ignore ? _OnPropShared_1 : _OnPropShared_2
        OnProp := OnPropShared.Bind([_SetProp_, _SetPropArray_], OnPropOptionFuncs)
        if params.AllNumbersAreString
            HandleNumber := _HandleNumberQuote_
        else
            HandleNumber := _HandleNumber_
        if params.restoreClassType
            GetObjFuncs.Push(_ObjGetterClass_)
        if params.restoreMap {
            if params.NumericKeysAreString {
                OnBracketSquareClose := _OnBracketSquareCloseRestoreMap_.Bind(_MapSetterNumericKeysAreString_)
                GetObjFuncs.Push(_ObjGetterMap_.Bind(_MapSetterNumericKeysAreString_))
            } else {
                OnBracketSquareClose := _OnBracketSquareCloseRestoreMap_.Bind(_MapSetter_)
                GetObjFuncs.Push(_ObjGetterMap_.Bind(_MapSetter_))
            }
        } else
            OnBracketSquareClose := _OnBracketSquareClose_
        if params.restoreArray
            GetObjFuncs.Push(_ObjGetterArray_)
        OnBracketCurlyClose := GetObjFuncs.length ? _OnBracketCurlyCloseWithNewObj_.Bind(GetObjFuncs)
        : _OnBracketCurlyClose_
        len := StrLen(str)
        while RegExMatch(str, pattern, &match, pos) {
            ; objstr := '', depth.length > 0 ? Stringify(depth[1], &objstr, {ignore:['__ParseParentProp'], nlCharLimitArray:0, nlCharLimitMap: 0, nlCharLimitObj: 0}) : ''
            pos := (pos < match.pos + match.len ? match.pos + match.len : pos)
            if !mod(A_index, 100000) {
                outputdebug('`n' pos / len)
            }
            ; _OutputDebug_(A_ThisFunc, A_LineNumber, pos, match, objstr)
        }

        if IsSet(duplicateObjects) && duplicateObjects.length
            _RestoreDuplicates_()
        return obj

        _OutputDebug_(fn, ln, pos, match, extra) {
            OutputDebug(Format('`n{:-30} {:-6} {:-10} {:-30} `n {} `n`n', fn, ln, pos, match[0], extra))
        }



        _Out_() {
            if obj.HasOwnProp(params.tempPropTag)
                obj.DeleteProp(params.tempPropTag)
            obj := depth.Pop()
        }
        _OnPropShared_1(SetPropFuncs, OnPropOptionFuncs, match, *) {
            static propFuncIndex := 1
            for item in params.ignore {
                if match['prop'] == item
                    return
            }
            if match[2] == '"' {
                if !RegExMatch(str, '"(?<value>.*?(?<!\\)(?:\\\\)*)"', &matchQuote, match.pos + match.len - 1)
                    _ThrowNoMatchingQuoteError_(match)
                val := OnPropOptionFuncs[1](matchQuote), pos := matchQuote.pos + matchQuote.len
            } else
                val := _GetVal_(match)
            if val {
                try
                    SetPropFuncs[propFuncIndex](val, match)
                catch Error as err {
                    if match['prop'] == '__Item' && Type(obj) == 'Array'
                        propFuncIndex := 2
                    else if propFuncIndex == 2
                        propFuncIndex := 1
                    else if err.message != 'Property is read-only.'
                        throw err
                        ; OutputDebug('Error OnProp: ' err.message '`n'), err := ''
                    SetPropFuncs[propFuncIndex](val, match)
                }
                OnPropOptionFuncs[2](val, match)
            }
        }
        _OnPropShared_2(SetPropFuncs, OnPropOptionFuncs, match, *) {
            static propFuncIndex := 1
            if match[2] == '"' {
                if !RegExMatch(str, '"(?<value>.*?(?<!\\)(?:\\\\)*)"', &matchQuote, match.pos + match.len - 1)
                    _ThrowNoMatchingQuoteError_(match)
                val := OnPropOptionFuncs[1](matchQuote), pos := matchQuote.pos + matchQuote.len
            } else
                val := _GetVal_(match)
            if val {
                try
                    SetPropFuncs[propFuncIndex](val, match)
                catch Error as err {
                    if match['prop'] == '__Item' && Type(obj) == 'Array'
                        propFuncIndex := 2
                    else if propFuncIndex == 2
                        propFuncIndex := 1
                    else if err.message != 'Property is read-only.'
                        throw err
                        ; OutputDebug('Error OnProp: ' err.message '`n'), err := ''
                    SetPropFuncs[propFuncIndex](val, match)
                }
                OnPropOptionFuncs[2](val, match)
            }
        }
        _SetProp_(val, match) {
            obj.%match['prop']% := IsObject(val) ? val : IsNumber(Val) && !params.AllNumbersAreString ? Number(Val)
            : StrReplace(params.ConvertNewLine ? RegExReplace(val, '(\\[rn])+', params.ConvertNewLine)
            : val, '\"', '"')
        }
        _SetPropArray_(val, *) => obj.Push(val)
        _HandleVal_(val, match) {
            if IsObject(val)
                depth.Push(obj), val.%params.tempPropTag% := match['prop'], obj := val
        }
        _HandleValDuplicateObjects_(val, match) {
            if IsObject(val)
                depth.Push(obj), val.%params.tempPropTag% := match['prop'], obj := val
            else if Type(val) == 'String' && RegExMatch(val, '^"\{\$\.[^\}]+\}"')
                duplicateObjects.Push({obj: obj, prop: match['prop'], val: val})
        }
        _RestoreDuplicates_() {
            local dupObj, split, collection := Map()
            for item in duplicateObjects {
                if collection.Has(item.val) {
                    obj.%match['prop']% := collection[item.val]
                    continue
                }
                split := item.val.Split('.'), dupObj := depth[1]
                for pathItem in split {
                    ; Reminder: Modify Stringify to replace dots and spaces with underscores in object paths.
                    switch Type(dupObj) {
                        case 'Array':
                            dupObj := dupObj[Number(Trim(pathItem, '#'))]
                        case 'Map':
                            dupObj := dupObj[pathItem]
                        default:
                            dupObj := dupObj.%pathItem%
                    }
                }
                collection.Set(item.val, dupObj)
                obj.%item.prop% := dupObj
            }
        }
        _OnProp_(matchQuote) {
            return RegExMatch(matchQuote[0], '^"\{[^}]+\}("$| :: Error:)') ? '' : matchQuote['value']
        }
        _OnPropIncludePlaceholders_(matchQuote) => matchQuote[0] != '"{Func}"'
        && matchQuote[0] != '"{BoundFunc}"' && matchQuote[0] != '"{Closure}"' ? matchQuote[0] : ''
        _OnPropIncludeFuncPlaceholders_(matchQuote) => !RegExMatch(matchQuote[0], '^"\{[^}]+\}("$| :: Error:)')
        || matchQuote[0] == '"{Func}"' || matchQuote[0] == '"{BoundFunc}"' || matchQuote[0] == '"{Closure}"'
        ? matchQuote[0] : ''
        _OnPropIncludeAllPlaceholders_(matchQuote) => matchQuote[0]
        OnNumber(match, *) => obj.Push(HandleNumber(match))
        OnQuote(match, *) {
            obj.Push(match['value'])
        }
        OnKeyword(match, *) => obj.Push(match[0])
        OnBracketSquare(match, *) {
            if !params.maxDepth || depth.length < params.maxDepth
                depth.Push(obj), pattern := patternArrActive, obj.Push([]), obj := obj[-1]
        }
        OnBracketCurly(match, *) {
            if !params.maxDepth || depth.length < params.maxDepth
                depth.Push(obj), pattern := patternObjActive, obj.Push({}), obj := obj[-1]
        }
        _MapSetterNumericKeysAreString_(newObj, key, val) => newObj.Set(IsNumber(key) ? String(key) : key, val)
        _MapSetter_(newObj, key, val) => newObj.Set(key, val)
        _OnBracketSquareCloseRestoreMap_(MapSetter, match, *) {
            local flagIsMap := true, newObj := Map()
            if obj.Length {
                for item in obj {
                    if Type(item) != 'Array' || item.length != 2 || (Type(item[1]) != 'String' && !IsNumber(item[1])) {
                        flagIsMap := false
                        break
                    }
                    MapSetter(newObj, item[1], item[2])
                }
            } else
                flagIsMap := false
            if flagIsMap && depth.length {
                switch Type(depth[-1]) {
                    case 'Array':
                        depth[-1][2] := newObj
                    case 'Map':
                        tempProp := obj.%params.tempPropTag%
                        depth[-1].Set(%tempProp%, newObj)
                    default:
                        tempProp := obj.%params.tempPropTag%
                        depth[-1].%tempProp% := newObj
                }
            }
            if depth.length
                _Out_()
            pattern := Type(obj) == 'Array' ? patternArrActive : patternObjActive
        }
        _OnBracketSquareClose_(match, *) {
            if depth.length
                _Out_()
            pattern := Type(obj) == 'Array' ? patternArrActive : patternObjActive
        }
        _OnBracketCurlyClose_(match, *) {
            obj.DeleteProp(params.tempPropTag)
            if depth.length
                _Out_()
            pattern := Type(obj) == 'Array' ? patternArrActive : patternObjActive
        }
        _OnBracketCurlyCloseWithNewObj_(GetObjFuncs, match, *) {
            local newObj
            for fn in GetObjFuncs {
                if newObj := fn()
                    break
            }
            if newObj && depth.length {
                switch Type(depth[-1]) {
                    case 'Array':
                        depth[-1][-1] := newObj
                    ; case 'Map':
                    ;     depth[-1].Set(%obj.%params.tempPropTag%%, newObj)
                    default:
                        tempProp := obj.%params.tempPropTag%
                        depth[-1].%tempProp% := newObj
                }
                for prop in obj.OwnProps() {
                    if !newObj.HasOwnProp(prop)
                        newObj.%prop% := obj.%prop%
                }
            }
            if depth.length
                _Out_()
            pattern := Type(obj) == 'Array' ? patternArrActive : patternObjActive
        }
        _ObjGetterArray_() {
            if obj.HasOwnProp(params.itemContainerArray) {
                newObj := obj.%params.itemContainerArray%, obj.DeleteProp(params.itemContainerArray)
                return newObj
            }
        }
        _ObjGetterMap_(MapSetter) {
            if obj.HasOwnProp(params.itemContainerMap) && Type(obj.%params.itemContainerMap%) != 'Map' {
                newObj := Map()
                for item in obj.%params.itemContainerMap%
                    MapSetter(newObj, item[1], item[2])
                obj.DeleteProp(params.itemContainerMap)
                return newObj
            }
        }
        _ObjGetterClass_() {
            if obj.HasOwnProp('Prototype') {
                classObj := _TracePath_(Trim(obj.Prototype.__Class, '"'))
                try
                    ObjSetBase(obj, classObj)
                catch Error as err {
                    if params.showRestoreClassTypeErrors
                        throw err
                }
            } else if obj.HasOwnProp('__Class') {
                classObj := _TracePath_(Trim(obj.__Class, '"'))
                try
                    ObjSetBase(obj, classObj.Prototype)
                catch Error as err {
                    if params.showRestoreClassTypeErrors
                        throw err
                }
            }
            _TracePath_(path) {
                local split := StrSplit(path, '.')
                classObj := %split[1]%, i := 1
                while ++i <= split.length
                    classObj := classObj.%split[i]%
                return classObj
            }
        }
        _GetVal_(match) {
            switch match[2] {
                case '[':
                    if !params.maxDepth || depth.length < params.maxDepth {
                        pattern := patternArrActive
                        return []
                    }
                    return
                case '{':
                    if !params.maxDepth || depth.length < params.maxDepth {
                        pattern := patternObjActive
                        return {}
                    }
                    return
            }
            if RegExMatch(str, p.num, &matchNum, match.pos + match.len - 1) && matchNum.Pos == match.pos[2] {
                return HandleNumber(matchNum)
            }
            switch SubStr(str, match.pos[2], 4) {
                case 'true':
                    pos += 4
                    return true
                case 'fals':
                    pos += 5
                    return false
                case 'null':
                    pos += 4
                    return params.nullValue
            }
            throw ValueError('An unexpected value was encountered.',, 'Context: ' match[0] '`tPosition: ' match.pos)
        }
        _HandleNumber_(matchNum) {
            pos := matchNum.pos + matchNum.len
            n := matchNum['e'] ? Number(matchNum['n']) * (10 ** Number(matchNum['e'])) : Number(matchNum[0])
            return  Number(n)
        }
        _HandleNumberQuote_(matchNum) {
            pos := matchNum.pos + matchNum.len
            n := matchNum['e'] ? Number(matchNum['n']) * (10 ** Number(matchNum['e'])) : Number(matchNum[0])
            return String(n)
        }
        _ThrowNoMatchingQuoteError_(match) {
            throw ValueError('A matching quote was not found, indicating a syntax error.'
            ,, 'Context: ' match[0] '`tPosition: ' match.pos)
        }
    }
    class null {
        static __New() => ObjSetBase(this, this())
    }
}
