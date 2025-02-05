

Object.Prototype.DefineProp('Stringify', { Call: OBJECT_STRINGIFYA })
OBJECT_STRINGIFYA(Self, &Str, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    local PrepareNext
    if Object.Prototype.HasOwnProp('__StringifyController') {
        Controller := Object.Prototype.__StringifyController
        Controller.IndentLevel++
        Controller.Depth++
        _Indent := Controller.Indent
    } else {
        Controller := Object.Prototype.__StringifyController := {
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
                if DynamicPropAction == 2
                    continue
                else if !Self.GetOwnPropDesc(Prop).HasOwnProp('Value')
                    Prop := '__Dynamic_' Prop
            }
            Str .= Prop ': '
            if Val is ComObject || Val is ComValue {
                Str .= '"{ ' Strfy_GetType(Val) ' }"'
                continue
            }
            if IsObject(Val) {
                if Controller.Objects.Has(ObjPtr(Val))
                    Str .= '"{ ' Controller.Objects.Get(ObjPtr(Val)) ' }"'
                else if MaxDepth > 0 && Controller.Depth >= MaxDepth
                    Str .= '"{ ' Strfy_GetType(Val) ' }"'
                else {
                    Controller.Path.Push(Controller.Path[-1] '.' Prop)
                    Controller.Objects.Set(ObjPtr(Val), Controller.Path[-1])
                    Val.Stringify(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
                }
            } else
                Strfy_GetVal(&Val, &Str)
        }
        Controller.IndentLevel--
        Str .= Newline (Controller.IndentLevel ? _Indent.GetA(Controller.IndentLevel) : '') '}'
    } else {
        Controller.IndentLevel--
        Str .= '}'
    }
    Controller.Depth--
    if Controller.Depth {
        Controller.Path.Pop()
    } else {
        Object.Prototype.DeleteProp('__StringifyController')
    }
    return Str

    _PrepareNext(&Str) {
        Str .= Newline _Indent.GetA(Controller.IndentLevel)
        PrepareNext := _PrepareNextWithComma
    }
    _PrepareNextWithComma(&Str) {
        Str .= ',' Newline _Indent.GetA(Controller.IndentLevel)
    }
}

Array.Prototype.DefineProp('Stringify', { Call: ARRAY_STRINGIFYA })
ARRAY_STRINGIFYA(Self, &Str, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    local PrepareNext
    if Object.Prototype.HasOwnProp('__StringifyController') {
        Controller := Object.Prototype.__StringifyController
        Controller.IndentLevel++
        Controller.Depth++
        _Indent := Controller.Indent
    } else {
        Controller := Object.Prototype.__StringifyController := {
            Depth: 1, Objects: Map(), Indent: _Indent := [Indent], IndentLevel: 1, Path: ['$']
        }
        _Indent.DefineProp('GetA', { Call: ((Indent, Self, Index) => Self.Length < Index ?
        (Self.Push(Self[-1] Indent) || Self[Index]) : Self[Index]).Bind(Indent) })
    }
    Str .= '['
    if Self.Length {
        _SetArrayItems(&Str)
        Controller.IndentLevel--
        Str .= Newline (Controller.IndentLevel ? _Indent.GetA(Controller.IndentLevel) : '') ']'
    } else {
        Str .= ']'
        Controller.IndentLevel--
    }
    Controller.Depth--
    if Controller.Depth {
        Controller.Path.Pop()
    } else {
        Object.Prototype.DeleteProp('__StringifyController')
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
    }

    _HandleVal(&Val, &Str, &Prop?, Index?) {
        if Val is ComObject || Val is ComValue {
            Str .= '"{ ' Strfy_GetType(Val) ' }"'
            return
        }
        if IsObject(Val) {
            if Controller.Objects.Has(ObjPtr(Val))
                Str .= '"{ ' Controller.Objects.Get(ObjPtr(Val)) ' }"'
            else if MaxDepth > 0 && Controller.Depth >= MaxDepth
                Str .= '"{ ' Strfy_GetType(Val) ' }"'
            else {
                if IsSet(Prop)
                    Controller.Path.Push(Controller.Path[-1] '.' Prop)
                else
                    Controller.Path.Push(Controller.Path[-1] '[' Index ']')
                Controller.Objects.Set(ObjPtr(Val), Controller.Path[-1])
                Val.Stringify(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
            }
        } else
            Strfy_GetVal(&Val, &Str)
    }
    
    _PrepareNext(&Str) {
        Str .= Newline _Indent.GetA(Controller.IndentLevel)
        PrepareNext := _PrepareNextWithComma
    }
    _PrepareNextWithComma(&Str) {
        Str .= ',' Newline _Indent.GetA(Controller.IndentLevel)
    }
}

Map.Prototype.DefineProp('Stringify', { Call: MAP_STRINGIFYA })
MAP_STRINGIFYA(Self, &Str, Indent := '`s`s`s`s', Newline := '`r`n'
, MaxDepth := -1, IgnoreProps := 'i)^(?:Base|Prototype)$', DynamicPropAction := 0) {
    local PrepareNext
    if Object.Prototype.HasOwnProp('__StringifyController') {
        Controller := Object.Prototype.__StringifyController
        Controller.IndentLevel++
        Controller.Depth++
        _Indent := Controller.Indent
    } else {
        Controller := Object.Prototype.__StringifyController := {
            Depth: 1, Objects: Map(), Indent: _Indent := [Indent], IndentLevel: 1, Path: ['$']
        }
        _Indent.DefineProp('GetA', { Call: ((Indent, Self, Index) => Self.Length < Index ?
        (Self.Push(Self[-1] Indent) || Self[Index]) : Self[Index]).Bind(Indent) })
    }
    Str .= 'Map('
    if Self.Count {
        _SetMapItems(&Str)
        Controller.IndentLevel--
        Str .= Newline (Controller.IndentLevel ? _Indent.GetA(Controller.IndentLevel) : '') ')'
    } else {
        Str .= ')'
        Controller.IndentLevel--
    }
    Controller.Depth--
    if Controller.Depth {
        Controller.Path.Pop()
    } else {
        Object.Prototype.DeleteProp('__StringifyController')
    }
    return Str

    _SetMapItems(&Str) {
        PrepareNext := _PrepareNext
        for Key, Val in Self {
            PrepareNext(&Str)
            if IsObject(Key) {
                Str .= '"{ ' Strfy_GetType(Key) ' }",' Newline _Indent.GetA(Controller.IndentLevel)
            } else {
                Strfy_GetVal(&Key, &Str)
                Str .= ',' Newline _Indent.GetA(Controller.IndentLevel)
            }
            _HandleVal(&Val, &Str,, &Key)
        }
    }

    _HandleVal(&Val, &Str, &Prop?, &Key?) {
        if Val is ComObject || Val is ComValue {
            Str .= '"{ ' Strfy_GetType(Val) ' }"'
            return
        }
        if IsObject(Val) {
            if Controller.Objects.Has(ObjPtr(Val))
                Str .= '"{ ' Controller.Objects.Get(ObjPtr(Val)) ' }"'
            else if MaxDepth > 0 && Controller.Depth >= MaxDepth + 1
                Str .= '"{ ' Strfy_GetType(Val) ' }"'
            else {
                if IsSet(Prop)
                    Controller.Path.Push(Controller.Path[-1] '.' Prop)
                else
                    Controller.Path.Push(Controller.Path[-1] '[' Key ']')
                Controller.Objects.Set(ObjPtr(Val), Controller.Path[-1])
                Val.Stringify(&Str, Indent, Newline, MaxDepth, IgnoreProps, DynamicPropAction)
            }
        } else
            Strfy_GetVal(&Val, &Str)
    }
    
    _PrepareNext(&Str) {
        Str .= Newline _Indent.GetA(Controller.IndentLevel)
        PrepareNext := _PrepareNextWithComma
    }
    _PrepareNextWithComma(&Str) {
        Str .= ',' Newline _Indent.GetA(Controller.IndentLevel)
    }
}
Strfy_GetType(Val) {
    return (Val is Class ? Val.Prototype.__Class: Type(Val) == 'Prototype' ? Val.__Class
    : Val.Base.__Class) ':' Type(Val)
}
Strfy_GetVal(&Val, &Str) {
    local pos, match
    if IsNumber(Val) {
        Str .= Val
        return
    }
    Val := StrReplace(Val, '\', '\\')
    Val := StrReplace(StrReplace(Val, '`n', '\n'), '`r', '\r')
    Val := StrReplace(StrReplace(Val, '"', '\"'), '`t', '\t')
    pos := 0
    while pos := RegExMatch(Val, '[^\x00-\x7F]', &match, pos+1)
        Val := StrReplace(Val, match[0], Format('\u{:04X}', Ord(match[0])))
    Str .= '"' Val '"'
}
