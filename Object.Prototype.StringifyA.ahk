/*
    Github: https://github.com/Nich-Cebolla/Stringify-ahk/blob/main/Object.Prototype.Stringify.ahk
    Author: Nich-Cebolla
    Version: 1.0.0
    License: MIT
*/

Object.Prototype.DefineProp('StringifyA', { Call: OBJECT_STRINGIFYA })
/**
 * @description - Produces a string representation of an object and its properties and items, if present.
 * The resulting string is represented in AutoHotkey's syntax, and can be used in a new script directly
 * to produce that object.
 * @param {Object} Self - The object to stringify. If calling this from an instance, exclude this
 * parameter.
 * @param {String:VarRef} [Str] - Reeives the resulting string. The string is also returned as a value,
 * but if you want the string to be appended to another string, you can set this parameter.
 * @param {String} [Indent='`s`s`s`s'] - The indentation to use for each level of depth.
 * @param {String} [Newline='`r`n'] - The newline character(s) to use.
 * @param {Number} [MaxDepth=-1] - The maximum depth to stringify. A value of -1 indicates no limit.
 * @param {String} [IgnoreProps='i)^(?:Base|Prototype)$'] - A regular expression to match property
 * names to ignore.
 * @param {Number} [DynamicPropAction=0] - The action to take for dynamic properties. There are three
 * valid values:
 * - 0: Use the default behavior as defined by AutoHotkey, which calls the property's getter and
 * uses the return value.
 * - 1: Omit the property.
 * - 2: Include the property and value but change the name of the property to `__Dynamic_<name>`.
 * @returns {String} - The string representation of the object.
 */
OBJECT_STRINGIFYA(Self, &Str?, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    global __StringifyAController
    if IsSet(__StringifyAController) {
        __StringifyAController.IndentLevel++
        __StringifyAController.Depth++
        _Indent := __StringifyAController.Indent
    } else {
        __StringifyAController := {
            Depth: 1, Objects: Map(), Indent: _Indent := [Indent], IndentLevel: 1, Path: ['$']
        }
        _Indent.DefineProp('GetA', { Call: ((Indent, Self, Index) => Self.Length < Index ?
        (Self.Push(Self[-1] Indent) || Self[Index]) : Self[Index]).Bind(Indent) })
    }
    Str .= '{'
    PrepareNext := _PrepareNext
    if ObjOwnPropCount(Self) {
        For Prop, Val in Self.OwnProps() {
            if RegExMatch(Prop, IgnoreProps)
                continue
            PrepareNext(&Str)
            if DynamicPropAction {
                Desc := Self.GetOwnPropDesc(Prop)
                if !Desc.HasOwnProp('Value') {
                    if DynamicPropAction == 2
                        continue
                    Prop := '__Dynamic_' Prop
                }
            }
            Str .= Prop ': '
            if Val is ComObject || Val is ComValue {
                Str .= '"{ ' StrfyA_GetType(Val) ' }"'
                continue
            }
            if IsObject(Val) {
                if __StringifyAController.Objects.Has(ObjPtr(Val))
                    Str .= '"{ ' __StringifyAController.Objects.Get(ObjPtr(Val)) ' }"'
                else if MaxDepth > 0 && __StringifyAController.Depth >= MaxDepth
                    Str .= '"{ ' StrfyA_GetType(Val) ' }"'
                else {
                    __StringifyAController.Path.Push(__StringifyAController.Path[-1] '.' Prop)
                    __StringifyAController.Objects.Set(ObjPtr(Val), __StringifyAController.Path[-1])
                    Val.StringifyA(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
                }
            } else
                StrfyA_GetVal(&Val, &Str)
        }
        __StringifyAController.IndentLevel--
        Str .= Newline (__StringifyAController.IndentLevel ? _Indent.GetA(__StringifyAController.IndentLevel) : '') '}'
    } else {
        __StringifyAController.IndentLevel--
        Str .= '}'
    }
    __StringifyAController.Depth--
    if __StringifyAController.Depth {
        __StringifyAController.Path.Pop()
    } else {
        __StringifyAController := unset
    }
    return Str

    _PrepareNext(&Str) {
        Str .= Newline _Indent.GetA(__StringifyAController.IndentLevel)
        PrepareNext := _PrepareNextWithComma
    }
    _PrepareNextWithComma(&Str) {
        Str .= ',' Newline _Indent.GetA(__StringifyAController.IndentLevel)
    }
}

Array.Prototype.DefineProp('StringifyA', { Call: ARRAY_STRINGIFYA })
/**
 * @description - Produces a string representation of an object and its properties and items, if present.
 * The resulting string is represented in AutoHotkey's syntax, and can be used in a new script directly
 * to produce that object.
 * @param {Array} Self - The object to stringify. If calling this from an instance, exclude this
 * parameter.
 * @param {String:VarRef} [Str] - Reeives the resulting string. The string is also returned as a value,
 * but if you want the string to be appended to another string, you can set this parameter.
 * @param {String} [Indent='`s`s`s`s'] - The indentation to use for each level of depth.
 * @param {String} [Newline='`r`n'] - The newline character(s) to use.
 * @param {Number} [MaxDepth=-1] - The maximum depth to stringify. A value of -1 indicates no limit.
 * @param {String} [IgnoreProps='i)^(?:Base|Prototype)$'] - A regular expression to match property
 * names to ignore.
 * @param {Number} [DynamicPropAction=0] - The action to take for dynamic properties. There are three
 * valid values:
 * - 0: Use the default behavior as defined by AutoHotkey, which calls the property's getter and
 * uses the return value.
 * - 1: Omit the property.
 * - 2: Include the property and value but change the name of the property to `__Dynamic_<name>`.
 * @returns {String} - The string representation of the object.
 */
ARRAY_STRINGIFYA(Self, &Str?, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    global __StringifyAController
    if IsSet(__StringifyAController) {
        __StringifyAController.IndentLevel++
        __StringifyAController.Depth++
        _Indent := __StringifyAController.Indent
    } else {
        __StringifyAController := {
            Depth: 1, Objects: Map(), Indent: _Indent := [Indent], IndentLevel: 1, Path: ['$']
        }
        _Indent.DefineProp('GetA', { Call: ((Indent, Self, Index) => Self.Length < Index ?
        (Self.Push(Self[-1] Indent) || Self[Index]) : Self[Index]).Bind(Indent) })
    }
    Str .= '['
    if Self.Length {
        _SetArrayItems(&Str)
        __StringifyAController.IndentLevel--
        Str .= Newline (__StringifyAController.IndentLevel ? _Indent.GetA(__StringifyAController.IndentLevel) : '') ']'
    } else {
        Str .= ']'
        __StringifyAController.IndentLevel--
    }
    __StringifyAController.Depth--
    if __StringifyAController.Depth {
        __StringifyAController.Path.Pop()
    } else {
        __StringifyAController := unset
    }
    return Str

    _SetArrayItems(&Str) {
        PrepareNext := _PrepareNext
        for Val in Self {
            PrepareNext(&Str)
            if IsSet(Val) {
                _HandleVal(&Val, &Str,, A_Index)
            } else
                Str .= '""'
        }

        _PrepareNext(&Str) {
            Str .= Newline _Indent.GetA(__StringifyAController.IndentLevel)
            PrepareNext := _PrepareNextWithComma
        }
        _PrepareNextWithComma(&Str) {
            Str .= ',' Newline _Indent.GetA(__StringifyAController.IndentLevel)
        }
    }

    _HandleVal(&Val, &Str, &Prop?, Index?) {
        if Val is ComObject || Val is ComValue {
            Str .= '"{ ' StrfyA_GetType(Val) ' }"'
            return
        }
        if IsObject(Val) {
            if __StringifyAController.Objects.Has(ObjPtr(Val))
                Str .= '"{ ' __StringifyAController.Objects.Get(ObjPtr(Val)) ' }"'
            else if MaxDepth > 0 && __StringifyAController.Depth >= MaxDepth
                Str .= '"{ ' StrfyA_GetType(Val) ' }"'
            else {
                if IsSet(Prop)
                    __StringifyAController.Path.Push(__StringifyAController.Path[-1] '.' Prop)
                else
                    __StringifyAController.Path.Push(__StringifyAController.Path[-1] '[' Index ']')
                __StringifyAController.Objects.Set(ObjPtr(Val), __StringifyAController.Path[-1])
                Val.StringifyA(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
            }
        } else
            StrfyA_GetVal(&Val, &Str)
    }
}

Map.Prototype.DefineProp('StringifyA', { Call: MAP_STRINGIFYA })
/**
 * @description - Produces a string representation of an object and its properties and items, if present.
 * The resulting string is represented in AutoHotkey's syntax, and can be used in a new script directly
 * to produce that object.
 * @param {Map} Self - The object to stringify. If calling this from an instance, exclude this
 * parameter.
 * @param {String:VarRef} [Str] - Reeives the resulting string. The string is also returned as a value,
 * but if you want the string to be appended to another string, you can set this parameter.
 * @param {String} [Indent='`s`s`s`s'] - The indentation to use for each level of depth.
 * @param {String} [Newline='`r`n'] - The newline character(s) to use.
 * @param {Number} [MaxDepth=-1] - The maximum depth to stringify. A value of -1 indicates no limit.
 * @param {String} [IgnoreProps='i)^(?:Base|Prototype)$'] - A regular expression to match property
 * names to ignore.
 * @param {Number} [DynamicPropAction=0] - The action to take for dynamic properties. There are three
 * valid values:
 * - 0: Use the default behavior as defined by AutoHotkey, which calls the property's getter and
 * uses the return value.
 * - 1: Omit the property.
 * - 2: Include the property and value but change the name of the property to `__Dynamic_<name>`.
 * @returns {String} - The string representation of the object.
 */
MAP_STRINGIFYA(Self, &Str?, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    global __StringifyAController
    if IsSet(__StringifyAController) {
        __StringifyAController.IndentLevel++
        __StringifyAController.Depth++
        _Indent := __StringifyAController.Indent
    } else {
        __StringifyAController := {
            Depth: 1, Objects: Map(), Indent: _Indent := [Indent], IndentLevel: 1, Path: ['$']
        }
        _Indent.DefineProp('GetA', { Call: ((Indent, Self, Index) => Self.Length < Index ?
        (Self.Push(Self[-1] Indent) || Self[Index]) : Self[Index]).Bind(Indent) })
    }
    Str .= 'Map('
    if Self.Count {
        _SetMapItems(&Str)
        __StringifyAController.IndentLevel--
        Str .= Newline (__StringifyAController.IndentLevel ? _Indent.GetA(__StringifyAController.IndentLevel) : '') ')'
    } else {
        Str .= ')'
        __StringifyAController.IndentLevel--
    }
    __StringifyAController.Depth--
    if __StringifyAController.Depth {
        __StringifyAController.Path.Pop()
    } else {
        __StringifyAController := unset
    }
    return Str

    _SetMapItems(&Str) {
        PrepareNext := _PrepareNext
        for Key, Val in Self {
            PrepareNext(&Str)
            if IsObject(Key) {
                Str .= '"{ ' StrfyA_GetType(Key) ' }",' Newline _Indent.GetA(__StringifyAController.IndentLevel)
            } else {
                StrfyA_GetVal(&Key, &Str)
                Str .= ',' Newline _Indent.GetA(__StringifyAController.IndentLevel)
            }
            _HandleVal(&Val, &Str,, &Key)
        }

        _PrepareNext(&Str) {
            Str .= Newline _Indent.GetA(__StringifyAController.IndentLevel)
            PrepareNext := _PrepareNextWithComma
        }
        _PrepareNextWithComma(&Str) {
            Str .= ',' Newline _Indent.GetA(__StringifyAController.IndentLevel)
        }
    }

    _HandleVal(&Val, &Str, &Prop?, &Key?) {
        if Val is ComObject || Val is ComValue {
            Str .= '"{ ' StrfyA_GetType(Val) ' }"'
            return
        }
        if IsObject(Val) {
            if __StringifyAController.Objects.Has(ObjPtr(Val))
                Str .= '"{ ' __StringifyAController.Objects.Get(ObjPtr(Val)) ' }"'
            else if MaxDepth > 0 && __StringifyAController.Depth >= MaxDepth + 1
                Str .= '"{ ' StrfyA_GetType(Val) ' }"'
            else {
                if IsSet(Prop)
                    __StringifyAController.Path.Push(__StringifyAController.Path[-1] '.' Prop)
                else
                    __StringifyAController.Path.Push(__StringifyAController.Path[-1] '[' Key ']')
                __StringifyAController.Objects.Set(ObjPtr(Val), __StringifyAController.Path[-1])
                Val.StringifyA(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
            }
        } else
            StrfyA_GetVal(&Val, &Str)
    }
}


StrfyA_GetType(Val) {
    return (Val is Class ? Val.Prototype.__Class : Type(Val) == 'Prototype' ? Val.__Class
    : Val.Base.__Class) ':' Type(Val)
}
StrfyA_GetVal(&Val, &Str) {
    local pos, match
    if IsNumber(Val) {
        Str .= Val
        return
    }
    Str .= '"' StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(StrReplace(Val, '``', '````')
    , '"', '``"'), '`t', '``t'), "'", "``'"), '`n', '``n'), '`r', '``r') '"'
}
