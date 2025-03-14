

class StringifyConfig {
    static enumAsMap := false
    static escapeNL := ''
    static hideErrors := true
    static ignore := []
    static indent := '`s`s`s`s'
    static itemContainerArray := '__ArrayItem'
    static itemContainerEnum := '__EnumItem'
    static itemContainerMap := '__MapItem'
    static maxDepth := 0
    static newline := '`n'
    static newlineDepthLimit := 0
    static nlCharLimitArray := 100
    static nlCharLimitMap := 100
    static nlCharLimitObj := 100
    static printFuncPlaceholders := false
    static quoteNumbersAsKey := true
    static recursePrevention := 1
    static singleLineArray := false
    static singleLineMap := false
    static singleLineObj := false
    static useEnum := true
    static useOwnProps := true
}

/** # Stringify
   ### Contents
        I. Description and Features
        II. Options
            A. Recursion and recursion prevention
                1. recursePrevention
                2. ignore
            B. Object iteration
                3. useOwnProps
                4. useEnum
                5. enumAsMap
            C. Spacing
                6. singleLineArray
                7. singleLineMap
                8. singleLineObj
                9. nlCharLimitArray
                10. nlCharLimitMap
                11. nlCharLimitObj
                12. newlineDepthLimit
                13. newline
                14. indent
                15. maxDepth
            D. Format
                16. printFuncPlaceholders
                17. hideErrors
                18. quoteNumbersAsKey
                19. escapeNL
                20. itemContainerArray
                21. itemContainerEnum
                22. itemContainerMap
        III. Details
*/

    ;@region Description
/** ## Description

    Stringify is a function that converts an AHK object into a JSON string. I designed `Stringify`
    to output a 100% valid JSON string, while also enabling various customization options.

    The characteristics which set this function apart from other Stringify functions are:
        - Iterate over all object properties, not just the base `__Enum` method.
        - Support for custom classes.
        - JSON string format and spacing customization.
        - Performs unicode character escape sequences automatically.
        - Error handling.
        - Recursion prevention.
        - Map items are represented as arrays of size-two arrays (lists of tuples): [ ["key", value], ["key", value] ]
        - A host of customization options.

    Function parameters can be defined in three ways. The keys/param names are the same for each.
    In selection order (top options are prioritized over bottom):
    - Passing an object to the function's third parameter.
    - Defining the options in this document.
    - Defining the options in `Stringify`'s static `params` property.
    
    The purpose of this document is to allow the user to define external default options, so
    if the main script is updated, the user is saved the hassle of needing to copy over their
    their preferred configuration. To use this external configuration, all one needs to do is
    either keep it in the same directory as the parent script, or #include it as one would
    any other script. `Stringify` will detect if this configuration is in use and adapt accordingly.
    The `params` parameter of the function accepts an object, and so any defaults can be superseded
    as needed on-the-fly.

    The limitations of this function are:
        - I have not written its counterpart, `Parse`, yet. But since it produces valid JSON, other
        parsers will work, with some considerations, listed a bit below.
        - Invoking a custom class' `__Enum` method expects that the method accepts two ByRef variables
        as parameters, in the standard `for k, v in obj` format. If the method is incompatible with
        this, the enumeration does not occur. Any properties that were captured prior are still
        maintained in the string, but the enumerable container is not included; its placeholder
        is printed instead. If `hideErrors` is, false, a placeholder is printed and the error text
        listed next to the placeholder. If `hideErrors` is true, only the placeholder is printed in
        the string.


        Parsing considerations
            - `Stringify` uses placeholder names for item containers when needed. For example, if
            a map object has also been assigned properties, `Stringify` does not assign the map's items
            to the the object itself. The items are assigned to a container property, by default named
            `__MapItem`. The names are customizable. But if this is parsed by another script, the
            map items will be on that property and the base object would be an object, not a map.
            See the section `useOwnProps` for more details.
            - Maps become arrays of size-two arrays, and so need to be converted back to maps if
            the parser is not designed to handle this.
            - `Stringify` includes placeholders for certain values. For example, objects that are
            not iterable such as functions are included in the string as '"{Func}"'.
*/
  
    ;@region Recursion
/**
    @property {Integer|String} [recursePrevention]
    This property can be used to prevent recursion. When using `Stringify`, if an object is assigned
    as a value to one of it's child properties, then `Stringify` will encounter infinite recursion
    without intervention. `recursePrevention` directs `Stringify` to assign a tag to each object
    that has been stringified. The tags are removed when the procedure exits. Options are:
    - 0 or false: No recursion prevention.
    - 1 or 'Recursion': `Stringify` will skip over properties when the value of the property is a
    parent object. Objects in general may be stringified more than once, but only if the subject
    does not contain a property that has a value that is a parent object.
    In the below example, `Stringify` will allow `obj.John` to be stringified twice, because they
    are on separate paths.
        @example
        obj := {
            John: {
                hairColor: 'brown',
                age: 30
            },
            Mary: {
                hairColor: 'blonde',
                age: 25,
                brother: ''
            }
        }
        obj.Mary.brother := obj.John
        Stringify(obj, &str)
        MsgBox(str)
        ; {
        ;     "John": {
        ;         "age": 30,
        ;         "hairColor": "brown"
        ;     },
        ;     "Mary": {
        ;         "age": 25,
        ;         "brother": {
        ;             "age": 30,
        ;             "hairColor": "brown"
        ;         },
        ;         "hairColor": "blonde"
        ;     }
        ; }
        @
        The below script will not allow `obj.John.favoriteSister.brother`, nor
        `obj.John.sister.brother` to be stringified because both would result in infinite recursion.
        @example
        obj := {
            John: {
                haircolor: 'brown',
                sister: {
                    name: 'Mary',
                    brother: ''
                },
                favoriteSister: ''
            }
        }
        obj.john.sister.brother := obj.john
        obj.john.favoriteSister := obj.john.sister
        Stringify(obj, &str)
        MsgBox(str)
        ; {
        ;     "John": {
        ;         "favoriteSister": {
        ;             "brother": "{$.John}",
        ;             "name": "Mary"
        ;         },
        ;         "haircolor": "brown",
        ;         "sister": {
        ;             "brother": "{$.John}",
        ;             "name": "Mary"
        ;         }
        ;     }
        ; }
        @

    - 2 or 'duplicate': All objects can be stringified a maximum of one time. If an object has been
    tagged, it will be skipped all subsequent encounters.

    When an object is skipped due to this option, a placeholder is applied to the JSON in the
    format `"{objectPath.objectName}"`. Looking at the above example, `$.` is the symbol for the
    root object, `John` is a first child of the root object. Since `$.John` was iterated first,
    that becomes the symbol used for subsequent encounters that are excluded due to this recursion
    setting.

    @property {String|Array} [ignore] - An array of strings or a single string that will be used to
    ignore properties when stringifying an object. There are two approaches to using this option.
    - Strict mode: If your object has properties that share a name, and you want to exclude one but
    not the other, then you must distinguish them by including the path. For `Stringify` to know to
    use strict mode, begin the path with the root symbol `$.` and include the path to the property
    including property name.
    @example
    fuzziestAnimals := {
        Mammals: {
            Bears: {
                Grizzly: {
                    fur: 'brown',
                    size: 'large'
                },
                Panda: {
                    fur: 'black and white',
                    size: 'medium'
                }
            },
            Koala: {
                fur: 'gray',
                size: 'small'
            }
        }
    }
    params := {ignore: ['$.Mammals.Bears.Grizzly']}
    Stringify(fuzziestAnimals, &str, params)
    MsgBox(str)
    ; {
    ;     "Mammals": {
    ;         "Bears": {
    ;             "Panda": {
    ;                 "fur": "black and white",
    ;                 "size": "medium"
    ;             }
    ;         },
    ;         "Koala": {
    ;             "fur": "gray",
    ;             "size": "small"
    ;         }
    ;     }
    ; }
    @
    
    - Match mode: Any strings that are included in `ignore` that do not begin with `$.` are considered
    to be used for matching anywhere in an object's name. RegEx pattern matching is employed by
    direct application of the value. Below is the literal function in use, where `name` represent the
    key or property name of the object in question, `item` is an item in the `ignore` array,
    `this.active` contains the current object path up to but before the object's prop/key name.
    @example
    CheckIgnore(name) {
        if name == '__StringifyTag'
            return 1
        for item in this.ignore {
            if (SubStr(item, 1, 2) == '$.' && this.active '.' name == item) || RegExMatch(name, item)
                return 1
        }
    }
    @
*/
    ;@endregion




    ;@region Object Iteration
/**
   @property {Boolean} [useOwnProps] - When true, objects will iterate their properties first. The
   key concept here is that arrays, maps, and other class instances will iterate all of their
   properties, as opposed to just the items iterated by its `__Enum` method.
   
   The below script is an example of normal enumeration without this option.
   Enumerating the object does not capture the object's properties.
   @example
   data := Map('January', 10000, 'February', 20000, 'March', 15000)
   data.percentage := (data['January'] + data['February'] + data['March']) / 50000
   data.source := 'www.example.com'
   list := []
   for item in data
    list.Push({item:item, value: data[item]})
   MsgBox(list.length) ; 3
   @

   However, when `useOwnProps` is true, the object will iterate its properties first, before
   using the `__Enum` method.
   @example
   list := [], discarded := []
   for prop in data.OwnProps() {
        try
            val := data.%prop%, list.Push(prop)
        catch Error as err
            discarded.Push({prop: prop, error: err})
    }
    for prop in list
        _Process_(obj, prop)
    for key, val in data
        _Process_(key, val)
    @
    
    To prevent complications such as JSON syntax errors due to duplicate keys, or overwriting extant
    data, `Stringify` creates a faux property to add any items acquired through the `__Enum` method.
    The names are customizable, but the defaults are: `__ArrayItem`, `__MapItem`, and `__EnumItem`.
    This only occurs when `useOwnProps` is true. When false, the items are assigned as values to the
    property name, either in map form or array form.
    
    If an object already has a property with its associated item name, `Stringify` will append
    underscores repeatedly until a unique name is found.

    Although map items and Array items aren't properties, and therefore do not conflict with
    an object's property names, the purpose in implementing this option was to avoid errors when
    Stringifying custom classes that employ an `__Enum` method, since it would be unknown whether
    the class is enumerating it's properties or a set of items or some other thing, and also it
    would be unknown where those values are contained. By default, when iterating over an object's
    `__Enum` method, `Stringify` assumes they are object properties unless either of these are true:
    option `enumAsMap` is true, or `Stringify` sets the `flagAsMap` flag as a result of the below test.
    @example
    try {
        for key, val in obj {
            if tracker.CheckIgnore(key)
                continue
            if IsObject(key)
                tracker.Discard({key:key, val:val, index:A_Index}, &discardGroup)
            else if RegExMatch(key, '^[^a-zA-Z_]|[^\w\d_]') {
                flagAsMap := true
                break
            }
            flagEnum := 1
        }
    } catch Error as err
        str .= _GetTypeString_(obj, err), keys := -1
    @
    
    The default settings will direct `Stringify` to iterate the properties, then invoke the
    `__Enum` method. Note that the `Object.Prototype.OwnProps()` method may have already
    cause `Stringify` to iterate the container. This shouldn't cause any problems but is worth
    being aware of.

    @property {Boolean} [useEnum] - When true, `Stringify` will iterate over the object's `__Enum`
    method. When false, the method is skipped. When employed, the method is activated using the
    standard two-parameter version of a `for` loop, expecting that the first parameter is the key,
    and the second parameter is the value. If the `__Enum` method is not compatible with this
    format, then the enumeration will fail and the items will be skipped.
    

    @property {Boolean} [enumAsMap] - When true, `Stringify` will treat the items acquired from the
    `__Enum` method as a map regardless of content.
*/
    ;@endregion
    



    ;@region Format and Spacing
/**

    -   -   -   -   -   -    -    -    -
    @property {Boolean} [singleLineArray]
    @property {Boolean} [singleLineMap]
    @property {Boolean} [singleLineObj]
    For these three properties, if true, all objects of that type are represented as single-line items.
    @example
    params := {singleLineArray: false, nlCharLimitArray: 5} ; note this says false
    obj := [1,3,3,4,5,6,7,9, ... 200]
    Stringify(obj, &str, params)
    MsgBox(str) ; [`n    1,`n    2,`n    3,`n    ...,    200`n]

    params := {singleLineArray: true}
    Stringify(obj, &str, params)
    MsgBox(str) ; [1,2,3,...200]
    @
    -   -   -   -   -   -   -   -   -   -

    @property {Integer} [nlCharLimitArray]
    @property {Integer} [nlCharLimitMap]
    @property {Integer} [nlCharLimitObj]
    For these three properties, assigning a positive integer value directs `Stringify` to print the
    object as a single line only if the number of characters in the object are less than or equal to
    the value. If the object exceeds the character limit, the object is printed in its expanded form.
    Character count includes all characters except leading whitespace (i.e. the characters between
    the beginning of the line and the first non-whitespace character. This process is facilitated
    by a tracking mechanism that logs the string length at each depth level, and keeps track of
    the number of newline characters and indent characters used up to that point. When the object's
    stringification is complete and that depth exits, the character count is calculated and compared
    with the limit. If the limit is exceeded, no changes are made. If the count is beneath the limit,
    the object is condensed to a single line.
    @example
    coolRocks := Map('geode', {weight: 5, color: 'purple'}, 'quartz', {weight: 3, color: 'white'}
                    , 'obsidian', {weight: 9, color: 'black'}, 'amethyst', {weight: 6, color: 'purple'})
    params := {nlCharLimitMap: 100}   ; limit of 100 characters
    Stringify(coolRocks, &str, params)
    MsgBox(str)
    ; [
    ;     [
    ;         "amethyst",
    ;         {
    ;             "color": "purple",
    ;             "weight": 6
    ;         }
    ;     ],
    ;     [
    ;         "geode",
    ;         {
    ;             "color": "purple",
    ;             "weight": 5
    ;         }
    ;     ],
    ;     [
    ;         "obsidian",
    ;         {
    ;             "color": "black",
    ;             "weight": 9
    ;         }
    ;     ],
    ;     [
    ;         "quartz",
    ;         {
    ;             "color": "white",
    ;             "weight": 3
    ;         }
    ;     ]
    ; ]

    params := {nlCharLimitMap: 300} ; limit of 300 characters
    Stringify(coolRocks, &str, params)
    MsgBox(str) ; [["amethyst",{"color": "purple","weight": 6}],["geode",{"color": "purple","weight": 5}],
        ; ["obsidian",{"color": "black","weight": 9}],["quartz",{"color": "white","weight": 3}]]

    @
    -   -   -   -   -   -   -   -   -   -

    @property {Integer} [newlineDepthLimit] - When a positive integer, `Stringify` will only print
    new lines at depths equal to or less than the value. All other values will be printed in single-
    line form. The root object is depth 0. `0` is not a valid value for this parameter. If you
    don't want any newlines, set `newline` to `""`.
    @example
    theyreMineralsMarie := {
        geode: {weight: 5, colorRange: ['purple', 'blue', 'green']},
        quartz: {weight: 3, colorRange: ['white', 'clear']},
        obsidian: {weight: 9, colorRange: ['black', 'dark green']},
        amethyst: {weight: 6, colorRange: ['purple', 'violet']}
    }
    params := {newlineDepthLimit: 2, nlCharLimitArray: 5}
    Stringify(theyreMineralsMarie, &str, params)
    MsgBox(str)
    ; {
    ;     "amethyst": {
    ;         "colorRange": [
    ;             "purple",
    ;             "violet"
    ;         ],
    ;         "weight": 6
    ;     },
    ;     "geode": {
    ;         "colorRange": [
    ;             "purple",
    ;             "blue",
    ;             "green"
    ;         ],
    ;         "weight": 5
    ;     },
    ;     "obsidian": {
    ;         "colorRange": [
    ;             "black",
    ;             "dark green"
    ;         ],
    ;         "weight": 9
    ;     },
    ;     "quartz": {
    ;         "colorRange": [
    ;             "white",
    ;             "clear"
    ;         ],
    ;         "weight": 3
    ;     }
    ; }

    params := {newlineDepthLimit: 1, nlCharLimitArray: 5}
    Stringify(theyreMineralsMarie, &str, params)
    MsgBox(str)
    ; {
    ;     "amethyst": {
    ;         "colorRange": ["purple","violet"],
    ;         "weight": 6
    ;     },
    ;     "geode": {
    ;         "colorRange": ["purple","blue","green"],
    ;         "weight": 5
    ;     },
    ;     "obsidian": {
    ;         "colorRange": ["black","dark green"],
    ;         "weight": 9
    ;     },
    ;     "quartz": {
    ;         "colorRange": ["white","clear"],
    ;         "weight": 3
    ;     }
    ; }
    @

    @property {String} [newline] - The string of characters used to represent a new line. These
    are literal newlines within the JSON string, not escaped newlines.
    
    @property {String} [indent] - The string of characters used for indentation. One instance of this
    string is included for each indent level. For example: if this option is "`s`s`s`s" and the current
    indent level is 2, there will be 8 spaces before the line of text.

    @property {Integer} [maxDepth] - When a positive integer, `Stringify` will only print objects
    at depths equal to or less than the value. Any objects encountered that would require descending
    to a depth greater than this value are represented by their placeholder string.
    The root object is depth 0.
    @example
    class AnimeProtagonist {
        static Tiers := Map('Tier1', [], 'Tier2', [], 'Tier3', [])
        __New(name, details) {
            this.name := name, this.details := details
        }
    }
    for name, details in Map('Saitama', {power: 'One Punch', strength: 100}
    , 'Goku', {power: 'Kamehameha', strength: 90}, 'Naruto', {power: 'Rasengan', strength: 85})
        AnimeProtagonist.Tiers['Tier1'].Push(AnimeProtagonist(name, details))
    for name, details in Map('Luffy', {power: 'Gum-Gum Pistol', strength: 80}
    , 'Ichigo', {power: 'Getsuga Tensho', strength: 75}, 'Natsu', {power: 'Fire Dragon Roar', strength: 70})
        AnimeProtagonist.Tiers['Tier2'].Push(AnimeProtagonist(name, details))
    for name, details in Map('Yusuke', {power: 'Spirit Gun', strength: 65}
    , 'Gon', {power: 'Jajanken', strength: 60})
        AnimeProtagonist.Tiers['Tier3'].Push(AnimeProtagonist(name, details))
    
    params := {maxDepth: 2, nlCharLimitMap: 100}
    Stringify(AnimeProtagonist, &str, params)
    MsgBox(str)
    ; {
    ;     "__Init": "{Func}",
    ;     "Prototype": {
    ;         "__Class": "AnimeProtagonist",
    ;         "__New": "{Func}"
    ;     },
    ;     "Tiers": [
    ;         [
    ;             "Tier1",
    ;             ["{AnimeProtagonist}","{AnimeProtagonist}","{AnimeProtagonist}"]
    ;         ],
    ;         [
    ;             "Tier2",
    ;             ["{AnimeProtagonist}","{AnimeProtagonist}","{AnimeProtagonist}"]
    ;         ],
    ;         [
    ;             "Tier3",
    ;             ["{AnimeProtagonist}","{AnimeProtagonist}"]
    ;         ]
    ;     ]
    ; }
    @
    ;@endregion




    ;@region Format


    @property {Boolean} [printFuncPlaceholders] - When true, `Stringify` will include placeholders
    for functions in the JSON string. The placeholder will be `"{Func}"`, `"{BoundFunc}"`, or
    `"{Closure}"`. When false, functions are not included in the string.



    @property {Boolean} [hideErrors] - To allow this script to be generalizable to custom classes,
    some error handling is incorporated into `Stringify`. When `hideErrors` is false, `Stringify`
    includes error text within the JSON string next to the placeholder for the object that raised
    the error.

    Example hiding errors
    @example
    class CellPhone {
        static ComplicatedProcedure => IsSet(complicatedThing) ? complicatedThing : false
        static __Enum(params) {
            if CellPhone.ComplicatedProcedure
                return enumeration
            else
                throw MethodError('The procedure was too complicated!')
            i := 0
            enumeration(&a, &b) {
                if i > this.length
                    return 0
                a := this[i], b := i, i++
                return 1
            }
        }
        static __container := [100,200,300,400,500]
        static length => this.__container.length
    
        static __Item[index] {
            Get => this.__container[index]
            Set => this.__container[index] := value
        }
    }
    params := {hideErrors: true}
    Stringify(CellPhone, &str, params)
    msgbox(str)
    ; {
    ;     "__container": [100,200,300,400,500],
    ;     "__Enum": "{Func}",
    ;     "__Init": "{Func}",
    ;     "ComplicatedProcedure": 0,
    ;     "length": 5,
    ;     "Prototype": {
    ;         "__Class": "CellPhone"
    ;     },
    ;     "__EnumItem": "{Class:CellPhone}"
    ; }

    ; Example showing errors
    params := {hideErrors: false}
    Stringify(CellPhone, &str, params)
    msgbox(str)
    ; {
    ;     "__container": [100,200,300,400,500],
    ;     "__Enum": "{Func}",
    ;     "__Init": "{Func}",
    ;     "ComplicatedProcedure": 0,
    ;     "length": 5,
    ;     "Prototype": {
    ;         "__Class": "CellPhone"
    ;     },
    ;     "__EnumItem": "{Class:CellPhone} :: Error: Type: MethodError\nMessage: The procedure was'
    ; ' too complicated!\nWhat: CellPhone.__Enum\nFile: C:\\Users\\User\\Documents\\AutoHotkey\\Lib\\Stringify.ahk'
    ; ' \nLine: 9\nStack: C:\\Users\\User\\Documents\\AutoHotkey\\Lib\\Stringify.ahk (9) : [CellPhone.__Enum]'
    ; ' throw(MethodError(`'The procedure was too complicated!`'))\r\nC:\\Users\\User\\Documents\\'
    ; 'AutoHotkey\\Lib\\Stringify.ahk (74) : [Stringify.Call] For key in obj\r\nC:\\Users\\User\\'
    ; 'Documents\\AutoHotkey\\Lib\\Stringify.ahk (27) : [] Stringify(CellPhone, &str, params)\r\n>'
    ; 'Auto-execute\r\n"
    ; }
    @

    In the above example, when `Stringify` attempts to enumerate the class, it will try the
    `__Enum` method. When the error occurs, it will include the error information in the JSON string.
    Generally, when an error occurs, the object is not stringified and instead the placeholder is
    included. The exception is when iterating an object's `OwnProps()` method, in which case the
    error does not halt the process; only that specific property is skipped.

    Regarding standard arrays, unset indices are handle by `Stringify`. These are represented by `""`
    in the string. Regarding maps, no error handling is built-in. It is expected that a map's items
    are enumerable, and so if an error occurs we will want to see the error.

    @property {Boolean} [quoteNumbersAsKey] - When true, numbers are quoted when used as map keys.
    Example: Map(500, "value) becomes [["500", "value"]]. When false, the number is not quoted:
    [[500, "value"]].

    @property {String} [escapeNL] - The literal string of characters used to replace `r`n. When this
    option is set to empty or false, the characters are escaped by their usual counterpart.
    (i.e. "`r" is "\r" and "`n" is "\n"). When this option is set to a string, the literal string
    is used as a replacement for all matches with "\R"
    {@link https://www.autohotkey.com/docs/v2/misc/RegEx-QuickRef.htm#Common}.


    -   -   -   -   -   -   -   -   -   -
    @property {String} [itemContainerArray]
    @property {String} [itemContainerEnum]
    @property {String} [itemContainerMap]
    These properties are used to assign a placeholder for items acquired from the `__Enum` method.
    The default values are `__ArrayItem`, `__MapItem`, and `__EnumItem`. This only has an effect when
    `useOwnProps` is `true` and the stringified objects have properties that are accessible by
    `Object.Prototype.OwnProps()` in its 1-parameter mode. When `Stringify` gets to the enumeration
    method, it assigns any items accessed from the enumeration method to this property. If the object
    already has the designated name, `Stringify` will append underscores to the name until a unique
    name is found.
 */
    ;@endregion

    
