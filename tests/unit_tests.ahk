#Include dev_stringify.ahk

obj := {
    RO_1: 'RO_1',
    RO_2A: [
        'RO_2A_1',
        {
            RO_2A_2O_1: 'RO_2A_2O_1',
            RO_2A_2O_2A: [
                'RO_2A_2O_2A_1',
                Map(
                    'RO_2A_2O_2A_2M_1O',
                    {
                        RO_2A_2O_2A_2M_1O_1: 'RO_2A_2O_2A_2M_1O_1'
                    },
                    'RO_2A_2O_2A_2M_2A',
                    [
                        'RO_2A_2O_2A_2M_2A_1', 'RO_2A_2O_2A_2M_2A_2'
                    ]
                ),
                [
                    'RO_2A_2O_2A_2M_3A_1', 'RO_2A_2O_2A_2M_3A_2',
                    Map(
                        'RO_2A_2O_2A_2M_3A_3M_1O', {
                            RO_2A_2O_2A_2M_3A_3M_1O_1: 'RO_2A_2O_2A_2M_3A_3M_1O_1'
                        },
                        'RO_2A_2O_2A_2M_3A_3M_2A', [
                            'RO_2A_2O_2A_2M_3A_3M_2A_1', 'RO_2A_2O_2A_2M_3A_3M_2A_2'
                        ]
                    )
                ]
            ]
        }
    ],
    RO_3M: Map('RO_3M_1', 'RO_3M_1',
        'RO_3M_2', 'RO_3M_2',
        'RO_3M_3A', [
            'RO_3M_3A_1', 'RO_3M_3A_2', Map(
                'RO_3M_3A_3M_1', 'RO_3M_3A_3M_1',
                'RO_3M_3A_3M_2', 'RO_3M_3A_3M_2'
            )
        ]
    ),
    RO_4O: {
        RO_4O_1: 'RO_4O_1',
        RO_4O_2A: [
            'RO_4O_2A_1', 'RO_4O_2A_2', Map(
                'RO_4O_2A_3M_1', 'RO_4O_2A_3M_1',
                'RO_4O_2A_3M_2', 'RO_4O_2A_3M_2'
            )
        ]
    },
    RO_5M: Map(
        'RO_5M_1O', {
            RO_5M_1O_1: 'RO_5M_1O_1'
        }
    )
}

class MyClass {
    __New(val) {
        this.val := val
    }
    method() {
        return
    }
    static __New() {
        this.val := 'val'
    }
    static method() {
        return
    }
}

results := Map()


params := {
      callOwnProps: 2
    , ignoreProps: ''
    , ignoreKeys: ''
    , recursePrevention: 1
    , includeBuiltinTypes: false
    , includeBuiltinProps: ''
    , ignoreBuiltinProps: ''
    , includeGuiPos: false

    , indent: '`s`s`s`s'
    , newline: '`r`n'
    , maxDepth: 0
    , nlDepthLimit: 0
    , singleLine: false
    , singleLineArray: false
    , singleLineMap: false
    , singleLineObj: false
    , nlCharLimitAll: 0
    , nlCharLimitArray: 0
    , nlCharLimitMap: 0
    , nlCharLimitObj: 0

    , escapeNL: ''
    , printErrors: true
    , printFuncPlaceholders: false
    , printPlaceholders: false
    , quoteNumericKeys: true
    , printTypeTag: true
    , itemContainerArray: '__ArrayItem'
    , itemContainerMap: '__MapItem'

    , returnString: false
    , deleteTags: true
    , disable__Set: false
}

; callOwnProps, when 0 should throw a TypeError
; params.callOwnProps := 0
; test := 'callOwnProps-0-error'
; try
;     Stringify(obj, &str, params), results.Set(test, 'success')
; catch TypeError as err
;     results.Set(test, err.message)

; func placeholders should print
; test := 'callOwnProps-1-printFunncPlaceholders'
; params.callOwnProps := 1, params.printFuncPlaceholders := true
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; func placeholders should not print
; params.callOwnProps := 2, params.printFuncPlaceholders := true
;  test := 'callOwnProps-2-printFunncPlaceholders'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; `RO_2` should be ignored
; test := 'ignoreProps-string-match-mode'
; params.ignoreProps := 'RO_2'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; `$.RO_3O.RO_3O_2A` should be ignored
; params.ignoreProps := '$.RO_4O.RO_4O_2A'

; test := 'ignoreProps-string-strict-mode-obj'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; `$.RO_5M["RO_5M_1O"].RO_5M_1O_1` should be ignored
; params.ignoreProps := '$.RO_5M["RO_5M_1O"].RO_5M_1O_1'

; test := 'ignoreProps-string-strict-mode-mixed-map-object'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; `$.RO_5M["RO_5M_1O"]` should be ignored and the `__MapItem` placeholder should contain `[[]]`
; params.ignoreKeys := '$.RO_5M["RO_5M_1O"]'

; test := 'ignoreProps-string-strict-mode-map'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; `RO_5M_1O` should be ignored and the `__MapItem` placeholder should contain `[[]]`
; params.ignoreKeys := 'RO_5M_1O'

; test := 'ignoreProps-match-match-mode-map'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; `$.RO_4O.RO_4O_2A[3]["RO_4O_2A_3M_1"]` should be ignored
; params.ignoreKeys := '$.RO_4O.RO_4O_2A[3]["RO_4O_2A_3M_1"]'

; test := 'ignoreProps-match-strict-mode-with-array-item'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; `Critical Error: Function recursion limit exceeded.` error should occur.
; params.recursePrevention := 0
; obj.RO_2A[2].RO_2A_2O_1 := obj.RO_2A
; test := 'recursePrevention-0-critical-error'
; obj.class := MyClass
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; the string should stop at depth 20
; params.recursePrevention := 0, params.maxDepth := 20
; obj2 := {
;     prop1: 'val1'
;     , prop2: ''
; }
; obj2.prop2 := obj2

; test := 'recursePrevention-0-maxDepth-20'
; try {
;     Stringify(obj2, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; the string should print normally and `RO_2A_2O_1` should be ignored
; params.recursePrevention := 0, params.ignoreProps := 'RO_2A_2O_1'
; obj.RO_2A[2].RO_2A_2O_1 := obj.RO_2A

; test := 'recursePrevention-0-ignoreProps'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; the string should print normally and `RO_2A_2O_1` should be ignored
; params.recursePrevention := 1
; obj.RO_2A[2].RO_2A_2O_1 := obj.RO_2A

; test := 'recursePrevention-1'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; the string should print normally and `RO_2A_2O_1` should have a placeholder "{$.RO_2A}",
; params.recursePrevention := 1, params.printPlaceholders := true
; obj.RO_2A[2].RO_2A_2O_1 := obj.RO_2A

; test := 'recursePrevention-0-ignoreProps'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; the string should print normally and `RO_2A_2O_2A_2M_1O_1` should have a placeholder  "{$.RO_2A}",
; params.recursePrevention := 1, params.printPlaceholders := true
; obj.RO_2A[2].RO_2A_2O_2A[2]["RO_2A_2O_2A_2M_1O"].RO_2A_2O_2A_2M_1O_1 := obj.RO_2A

; test := 'recursePrevention-1-placeholder'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; the string should print normally and `RO_2A` should be an object with "RO_2A_2O_2A_2M_1O_1": "RO_2A_2O_2A_2M_1O_1"
; params.recursePrevention := 1, params.printPlaceholders := true
; obj.RO_2A := obj.RO_2A[2].RO_2A_2O_2A[2]["RO_2A_2O_2A_2M_1O"]

; test := 'recursePrevention-1-inverse'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; the string should print normally and `RO_2A_2O_2A_2M_1O` should have a placeholder "{$.RO_2A[2].RO_2A_2O_2A[2]}"
; params.recursePrevention := 1, params.printPlaceholders := true
; obj.RO_2A[2].RO_2A_2O_2A[2]["RO_2A_2O_2A_2M_1O"] := obj.RO_2A

; test := 'recursePrevention-2'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message





; the string should print normally and prop1 and prop2 should have placeholders
; params.recursePrevention := 2, params.printPlaceholders := true
; obj.prop1 := obj.RO_2A
; obj.prop2 := obj.RO_3M

; test := 'recursePrevention-duplicates'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; the string should print normally and prop1 and prop2 should have placeholders
; params.recursePrevention := 2, params.printPlaceholders := true
; obj.prop1 := obj.RO_2A
; obj.prop2 := obj.RO_3M

; test := 'recursePrevention-duplicates'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; indent should consist of $$$$
; params.indent := '$$$$'

; test := 'indent-$$$$'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message


; newline should consist of `n$`n
; params.newline := '`n$`n'

; test := 'newline-n$n'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; ; the JSON should be on 1 string but still have indentation
; params.newline := ''

; test := 'newline-empty-with-indent'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; the max depth 2
; params.maxDepth := 2, params.printPlaceholders := true

; test := 'maxDepth-2-printPlaceholders'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; everything past depth 1 should be on 1 line
; params.nlDepthLimit := 1

; test := 'nlDepthLimit-1'
; try {
    ; Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
    ; results.Set(test, 'error'), str := err.message



; everything map keys-value pairs under 15 characters should be on 1 line
; params.nlCharLimitMapItems := 15

; test := 'nlCharLimitMapItems-15'
; try {
    ; Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
    ; results.Set(test, 'error'), str := err.message




; params.singleline := true
; test := 'singleLineAll'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; params.singlelineMap := true
; test := 'singleLineAll-Map'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; params.singlelineArray := true
; test := 'singleLineAll-Array'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; params.singlelineObj := true
; test := 'singleLineAll-Obj'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; ; the largest object to be on a single line should be RO_2A_2O_2A[2] at 234 characters
; params.nlCharLimitAll := 250
; test := 'nlCharLimitAll-250'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message






; only RO_2A_2O_2A_2M_2A should be on a single line, as the smallest and with 45 characters
; params.nlCharLimitAll := 45
; test := 'nlCharLimitAll-45'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; params.nlCharLimitArray := 300
; test := 'nlCharLimitArray-300'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; params.nlCharLimitMap := 300
; test := 'nlCharLimitMap-300'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
    



; params.nlCharLimitObj := 300
; test := 'nlCharLimitObj-300'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
        
    

    
; class CellPhone {
;     static ComplicatedProcedure => IsSet(complicatedThing) ? complicatedThing : false
;     static Convert => CellPhone.GetValue()
;     static GetValue() {
;         if this.ComplicatedProcedure
;             return this.ComplicatedProcedure
;         else
;             throw MethodError('Unable to access ComplicatedProcedure.')
;     }
;     static __container := [100,200,300,400,500]
;     static length => this.__container.length

;     static __Item[index] {
;         Get => this.__container[index]
;         Set => this.__container[index] := value
;     }
; }
; ; should print error text for `__
; params.printErrors := true
; test := 'printErrors-true'
; try {
;     Stringify(CellPhone, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
  
    

    
; class CellPhone {
;     static ComplicatedProcedure => IsSet(complicatedThing) ? complicatedThing : false
;     static Convert => CellPhone.GetValue()
;     static GetValue() {
;         if this.ComplicatedProcedure
;             return this.ComplicatedProcedure
;         else
;             throw MethodError('Unable to access ComplicatedProcedure.')
;     }
;     static __container := [100,200,300,400,500]
;     static length => this.__container.length

;     static __Item[index] {
;         Get => this.__container[index]
;         Set => this.__container[index] := value
;     }
; }
; ; should only print Message, Line, and Type
; params.printErrors := 'MLT'
; test := 'printErrors-MLT'
; try {
;     Stringify(CellPhone, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
            
        


; obj2 := Map(500, '100', 600, '10000', 19000, '59999', '3834', 1000)
; params.quoteNumericKeys := true
; test := 'quoteNumericKeys-true'
; try {
;     Stringify(obj2, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
           
        

; outputdebug(str)


; obj2 := Map(500, '100', 600, '10000', 19000, '59999', '3834', 1000)
; params.quoteNumericKeys := false
; test := 'quoteNumericKeys-false'
; try {
;     Stringify(obj2, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
           



; params.printTypeTag := false
; test := 'printTypeTag-false'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message




; params.itemContainerArray := '__ItemTestArray'
; params.itemContainerMap := '__ItemTestMap'
; test := 'itemContainers'
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str := err.message
            

    
; params.returnString := true
; test := 'returnString'
; result := ''
; try {
;     result := Stringify(obj, &str, params), results.Set(test, result == str ? 1 : 0)
; } catch Error as err
;     results.Set(test, 'error'), str := err.message



; params.deleteTags := true
; test := 'deleteTags'
; global result := []
; try {
;     Stringify(obj, &str, params)
; } catch Error as err
;     results.Set(test, 'error'), str := err.message

; object.prototype.DefineProp('__Enum', {Call: (self, param, *) => self.OwnProps()})

; _CheckProps_(obj) {
;     global result
;     if obj.HasOwnprop('__StringifyTag')
;         result.push(obj)
;     for k, v in obj {
;         if IsObject(v)
;             _CheckProps_(v)
;     }

; }
; _CheckProps_(obj)
; results.Set(test, !result.length)


; We should see `capacity` and `length` on arrays, `capacity` on maps, and `ptr` on the buffer
; obj.prop1 := Buffer()
; params.includeBuiltinProps := 'array:length|capacity map:capacity buffer:ptr'
; test := 'includeBuiltinProps-length-capacity-ptr'
; try {
;     result := Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str .= err.message '`n' err.extra


; We should see `handle` and `__class`
; params.ignoreBuiltinProps := 'menu:ClickCount|Default', params.printErrors := true
; test := 'ignoreBuiltinProps-Menu-ClickCount-Default'
; obj.prop1 :=  Menu()
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str .= err.message '`n' err.extra



; We should see `Clickcount` and `default` and not see "handle" or "__class"
; params.includeBuiltinProps := 'menu:ClickCount|Default', params.printErrors := true
; test := 'ignoreBuiltinProps-Menu-ClickCount-Default'
; obj.prop1 :=  Menu()
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str .= err.message '`n' err.extra



; We should see the gui and three controls included
; g := Gui()
; g.Add('Button', 'x100 y100 w100 h25 vbtn', 'Button')
; g.Add('ListView', 'x10 y10 w80 h80 vlv', ['Col1', 'Col2'])
; g['lv'].Add(, 'Item1', 'Item2')
; g.Add('Edit', 'x10 y110 w100 h100 vedit', 'Text in the box')


; params.includeGui := true, params.printErrors := true
; test := 'ignoreBuiltinProps-Menu-ClickCount-Default'
; obj.prop1 :=  g
; try {
;     Stringify(obj, &str, params), results.Set(test, 'success')
; } catch Error as err
;     results.Set(test, 'error'), str .= err.message '`n' err.extra

Stringify(obj, &str, params)

outputdebug(str '`n`n')
sleep 1
; f := FileOpen(A_ScriptDIr '\unit-tests\' test '.txt', 'w')
; f.Write(str)
; f.Close()
    
; outputdebug((StrLen(str) > 1500 ? SubStr(str, strlen(str)-1500, 1500) : str) '`n`n' results[test] '`n`n')
; msgbox((StrLen(str) > 1500 ? SubStr(str, strlen(str)-1500, 1500) : str) '`n`n' results[test] '`n`n')
