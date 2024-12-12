
# Stringify

A customizable Stringify function that converts AHK objects to valid JSON strings.

<h2>Table of Contents</h2>

<ol type="I">
  <a href="#description-and-features"><li>Description and Features</li></a>
  <a href="#options"><li>Options</li></a>
    <ol type="A">
      <a href="#recursion-and-recursion-prevention"><li>Recursion and recursion prevention</li></a>
        <ol type="1">
          <a href="#recurseprevention"><li>recursePrevention</li></a>
          <a href="#ignore"><li>ignore</li></a>
        </ol>
      </li>
      <a href="#object-iteration"><li>Object iteration</li></a>
        <ol type="1">
          <a href="#useownprops"><li>useOwnProps</li></a>
          <a href="#useenum"><li>useEnum</li></a>
          <a href="#enumasmap"><li>enumAsMap</li></a>
        </ol>
      </li>
      <a href="#spacing"><li>Spacing</li></a>
        <ol type="1">
          <a href="#singlelinearray"><li>singleLineArray</li></a>
          <a href="#singlelinemap"><li>singleLineMap</li></a>
          <a href="#singlelineobj"><li>singleLineObj</li></a>
          <a href="#nlcharlimitarray"><li>nlCharLimitArray</li></a>
          <a href="#nlcharlimitmap"><li>nlCharLimitMap</li></a>
          <a href="#nlcharlimitobj"><li>nlCharLimitObj</li></a>
          <a href="#newlinedepthlimit"><li>newlineDepthLimit</li></a>
          <a href="#newline"><li>newline</li></a>
          <a href="#indent"><li>indent</li></a>
          <a href="#maxdepth"><li>maxDepth</li></a>
        </ol>
      </li>
      <a href="#format"><li>Format</li></a>
        <ol type="1">
          <a href="#hideerrors"><li>hideErrors</li></a>
          <a href="#quotenumbersaskey"><li>quoteNumbersAsKey</li></a>
          <a href="#escapenl"><li>escapeNL</li></a>
          <a href="#itemcontainerarray"><li>itemContainerArray</li></a>
          <a href="#itemcontainerenum"><li>itemContainerEnum</li></a>
          <a href="#itemcontainermap"><li>itemContainerMap</li></a>
        </ol>
      </li>
    </ol>
    <a href="#details"><li>Details</li></a>
      <ol type="A">
        <a href="#tracker"><li>Stringify.Tracker</li></a>
        <a href="#stringify"><li>Stringify</li></a>
        <a href="#_mapprocess_"><li>_MapProcess_</li></a>
        <a href="#call"><li>Stringify.Call</li></a>
        <a href="#ownprops-functions"><li>OwnProps Functions</li></a>
        <a href="#process-functions"><li>Process Functions</li></a>
        <a href="#setters"><li>Setters</li></a>
      </ol>
    </li>
</ol>


# Description and Features

`Stringify` is a function that converts an AHK object into a JSON string. I designed `Stringify` to output a 100% valid JSON string, while also enabling various customization options.

The characterstics which set this function apart from other Stringify functions are:
  - Iterate over all object properties, not just the base `__Enum` method.
  - Support for custom classes.
  - JSON string format and spacing customization.
  - Performs unicode character escape sequences automatically.
  - Error handling.
  - Full recursion into nested objects, with protection from infinite recursion.
  - Map items are represented as arrays of size-two arrays (lists of tuples): `[ ["key", value], ["key", value] ]`
  - A host of customization options.

Function parameters can be defined in three ways. The keys/param names are the same for each.
In selection order (top options are prioritized over bottom):
- Passing an object to the function's third parameter.
- Defining the options in the `StringifyConfig.ahk` file.
- Defining the options in `Stringify`'s static `params` property.

The purpose of the `StringifyConfiuration.ahk` is to allow the user to define external default options, so if the main script is updated, the user is saved the hassle of needing to copy over their preferred configuration. To use this external configuration, all one needs to do is either keep it in the same directory as the parent script, or #include it as one would any other script. `Stringify` will detect if this configuration is in use and adapt accordingly. The `params` parameter of the function accepts an object, and so any defaults can be supersededas needed on-the-fly.

The limitations of this function are:
- I have not written its counterpart, `Parse`, yet. But since it produces valid JSON, other parsers will work, with some considerations, listed a bit below.
- Invoking a custom class' `__Enum` method expects that the method accepts two ByRef varables as parameters, in the standard `for k, v in obj` format. If the method is incompatible with this, the enumeration does not occur. Any properties that were captured prior are still maintained in the string, but the enumerable container is not included; its placeholder is printed instead. If `hideErrors` is, false, a placeholder is printed and the error text listed next to the placeholder. If `hideErrors` is true, only the placeholder is printed in the string.

Parsing considerations:
- `Stringify` uses placeholder names for item containers when needed. For example, if a map object has also been assigned properties, `Stringify` does not assign the map's items to the the object itself. The items are assigned to a container property, by default named `__MapItem`. The names are customizable. But if this is parsed by another script, the map items will be on that property and the base object would be an object, not a map. See the section `useOwnProps` for more details.
- Maps become arrays of size-two arrays, and so need to be converted back to maps if the parser is not designed to handle this.
- `Stringify` includes placeholders for certain values. For example, objects that are not iterable such as functions are included in the string as `"{Func}"`.

# Options

## Alphabetic list

<li><a href="#enumasmap">enumAsMap</a><br></li>
<li><a href="#escapenl">escapeNL</a><br></li>
<li><a href="#hideerrors">hideErrors</a><br></li>
<li><a href="#ignore">ignore</a><br></li>
<li><a href="#indent">indent</a><br></li>
<li><a href="#itemcontainerarray">itemContainerArray</a><br></li>
<li><a href="#itemcontainerenum">itemContainerEnum</a><br></li>
<li><a href="#itemcontainermap">itemContainerMap</a><br></li>
<li><a href="#maxdepth">maxDepth</a><br></li>
<li><a href="#newline">newline</a><br></li>
<li><a href="#newlinedepthlimit">newlineDepthLimit</a><br></li>
<li><a href="#nlcharlimitarray">nlCharLimitArray</a><br></li>
<li><a href="#nlcharlimitmap">nlCharLimitMap</a><br></li>
<li><a href="#nlcharlimitobj">nlCharLimitObj</a><br></li>
<li><a href="#quotenumbersaskey">quoteNumbersAsKey</a><br></li>
<li><a href="#recurseprevention">recursePrevention</a><br></li>
<li><a href="#singlelinearray">singleLineArray</a><br></li>
<li><a href="#singlelinemap">singleLineMap</a><br></li>
<li><a href="#singlelineobj">singleLineObj</a><br></li>
<li><a href="#useenum">useEnum</a><br></li>
<li><a href="#useownprops">useOwnProps</a><br></li>


## Recursion and Recursion Prevention

### recursePrevention

{Integer|String}

This property can be used to prevent recursion. When using `Stringify`, if an object is assigned
as a value to one of it's child properties, then `Stringify` will encounter infinite recursion
without intervention. `recursePrevention` directs `Stringify` to assign a tag to each object
that has been stringified. The tags are removed when the procedure exits. Options are:
- 0 or false: No recursion prevention.
- 1 or "Recursion": `Stringify` will skip over properties when the value of the property is a parent object. Objects in general may be stringified more than once, but only when the subsequent occurrence of the object does not occur on a child's property.
- 2 or 'duplicate': All objects can be stringified a maximum of one time. If an object has been tagged, it will be skipped all subequent encounters.

When an object is skipped due to this option, a placeholder is applied to the JSON in theformat `"{objectPath.objectName}"`. Looking at the above example, `$.` is the symbol for the root object, `John` is a first child of the root object. Since `$.John` was iterated first,that becomes the symbol used for subsequent encounters that are excluded due to this recursion option.


In the below example, `Stringify` will allow `obj.John` to be stringified twice, because they are on separate paths.
```ahk
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
;{
;    "John": {
;        "age": 30,
;        "hairColor": "brown"
;    },
;    "Mary": {
;        "age": 25,
;        "brother": {
;            "age": 30,
;            "hairColor": "brown"
;        },
;        "hairColor": "blonde"
;    }
;}
```

The below script will not allow `obj.John.favoriteSister.brother`, nor, `obj.John.sister.brother` to be stringified because both would result in infinite recursion.

```ahk
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
;    {
;        "John": {
;            "favoriteSister": {
;                "brother": "{$.John}",
;                "name": "Mary"
;            },
;            "haircolor": "brown",
;            "sister": {
;                "brother": "{$.John}",
;                "name": "Mary"
;            }
;        }
;    }
```

### ignore

{String|Array}

An array of strings or a single string that will be used to ignore properties when stringifying an object. There are two approaches to using this option.

- Strict mode: If your object has properties that share a name, and you want to exclude one but not the other, then you must distinguish them by including the path. For `Stringify` to know to use strict mode, begin the path with the root symbol `$.` and include the path to the property including property name.
- Match mode: Any strings that are included in `ignore` that do not begin with `$.` are consideredto be used for matching anywhere in an object's name. RegEx pattern matching is employed by direct application of the value. Below is the literal function in use, where `name` represent the key or property name of the object in question, `item` is an item in the `ignore` array, `this.active` contains the current object path up to but before the object's prop/key name.

```ahk
CheckIgnore(name) {
    if name == '__StringifyTag'
        return 1
    for item in this.ignore {
        if (SubStr(item, 1, 2) == '$.' && this.active '.' name == item) || RegExMatch(name, item)
            return 1
    }
}
```
Example:
```ahk
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
;    {
;        "Mammals": {
;            "Bears": {
;                "Panda": {
;                    "fur": "black and white",
;                    "size": "medium"
;                }
;            },
;            "Koala": {
;                "fur": "gray",
;                "size": "small"
;            }
;        }
;    }
```

## Object Iteration

### useOwnProps

{Boolean}

When true, objects will iterate their properties first. The key concept here is that arrays, maps, and other class instances will iterate all of their properties, as opposed to just the items iterated by its `__Enum` method.
   
The below script is an example of normal enumeration without this option. Enumerating the object does not capture the object's properties.

```ahk
data := Map('January', 10000, 'February', 20000, 'March', 15000)
data.percentage := (data['January'] + data['February'] + data['March']) / 50000
data.source := 'www.example.com'
list := []
for item in data
list.Push({item:item, value: data[item]})
MsgBox(list.length)  ; 3
```

However, when `useOwnProps` is true, the object will iterate its properties first, before using the `__Enum` method. This is a conceptual script describing the process:

```ahk
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
```

    
To prevent complications such as JSON syntax errors due to duplicate keys, or overwriting extant data, `Stringify` creates a faux property to add any items acquired through the `__Enum` method. The names are customizable, but the defaults are: `__ArrayItem`, `__MapItem`, and `__EnumItem`. This only occurs when `useOwnProps` is true. When false, the items are assigned as values to the property name, either in map form or array form.

If an object already has a property with its associated item name, `Stringify` will append underscores repeatedly until a unique name is found.

Although map items and Array items aren't properties, and therefore do not conflict with an object's property names, the purpose in implementing this option was to avoid errors when Stringifying custom classes that employ an `__Enum` method, since it would be unknown whether the class is enumerating it's properties or a set of items or some other thing, and also it would be unknown where those values are contained. By defualt, when iterating over an object's `__Enum` method, `Stringify` assumes they are object properties unless either of these are true: option `enumAsMap` is true, or `Stringify` sets the `flagAsMap` flag as a result of the below test.

```ahk
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
```

### useEnum

{Boolean}

When true, `Stringify` will iterate over the object's `__Enum` method. When false, the method is skipped. When employed, the method is activated using the standard two-parameter version of a `for` loop, expecting that the first parameter is the key, and the second parameter is the value. If the `__Enum` method is not compatible with this format, then the enumeration will fail and the items will be skipped.

### enumAsMap

{Boolean}

When true, `Stringify` will treat the items acquired from the `__Enum` method as a map regardless of content.


## Spacing

### singleLineArray
### singleLineMap
### singleLineObj

{Boolean}

For these three properties, if true, all objects of that type are represented as single-line items.

```ahk
params := {singleLineArray: false, nlCharLimitArray: 5} ; note this says false
obj := [1,3,3,4,5,6,7,9, ... 200]
Stringify(obj, &str, params)
MsgBox(str) ; [
            ;     1,
            ;     2,
            ;     3,
            ;     4,
            ;    ...
            ;    200,
            ; ]

params := {singleLineArray: true}
Stringify(obj, &str, params)
MsgBox(str) ; [1,2,3,...200]
```

### nlCharLimitArray
### nlCharLimitMap
### nlCharLimitObj

{Integer}

For these three properties, assigning a positive integer value directs `Stringify` to print the object as a single line only if the number of characters in the object are less than or equal to the value. If the object exceeds the character limit, the object is printed in its expanded form. Character count includes all characters except leading whitespace (i.e. the characterss between the beginning of the line and the first non-whitespace character. This process is facilitated by a tracking mechanism that logs the string length at each depth level, and keeps track of the number of newline characters and indent characters used up to that point. When the object's stringification is complete and that depth exits, the character count is calculated and compared with the limit. If the limit is exceeded, no changes are made. If the count is beneath the limit, the object is condensed to a single line.

```ahk
coolRocks := Map('geode', {weight: 5, color: 'purple'}, 'quartz', {weight: 3, color: 'white'}
            , 'obsidian', {weight: 9, color: 'black'}, 'amethyst', {weight: 6, color: 'purple'})
params := {nlCharLimitMap: 100}    limit of 100 characters
Stringify(coolRocks, &str, params)
MsgBox(str)
[
    [
        "amethyst",
        {
            "color": "purple",
            "weight": 6
        }
    ],
    [
        "geode",
        {
            "color": "purple",
            "weight": 5
        }
    ],
    [
        "obsidian",
        {
            "color": "black",
            "weight": 9
        }
    ],
    [
        "quartz",
        {
            "color": "white",
            "weight": 3
        }
    ]
]

params := {nlCharLimitMap: 300}  limit of 300 characters
Stringify(coolRocks, &str, params)
MsgBox(str) ; [["amethyst",{"color": "purple","weight": 6}],["geode",{"color": "purple","weight": 5}],["obsidian",{"color": "black","weight": 9}],["quartz",{"color": "white","weight": 3}]]
```

### newlineDepthLimit

{Integer}

When a positive integer, `Stringify` will only print new lines at depths equal to or less than the value. All other values will be printed in single-line form. The root object is depth 0. `0` is not a valid value for this parameter. If you don't want any newlines, set `newline` to `""`.

```ahk
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
```

### newline

{String}

The string of characters used to represent a new line. These are literal newlines within the JSON string, not escaped newlines.

### indent

{String}

The string of characters used for indentation. One instance of this string is included for each indent level. For example: if this option is "`s`s`s`s" and the current indent level is 2, there will be 8 spaces before the line of text.

### maxDepth

{Integer}

When a positive integer, `Stringify` will only print objects at depths equal to or less than the value. Any objects encountered that would require descending to a depth greater than this value are represented by their placeholder string. The root object is depth 0.

```ahk
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
```

## Format

### hideErrors

{Boolean}

To allow this script to be generalizable to custom classes, some error handling is incorporated into `Stringify`. When `hideErrors` is false, `Stringify` includes error text within the JSON string next to the placeholder for the object that raised the error.

```ahk
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
; Example not showing errors
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
```

In the above example, when `Stringify` attempts to enumerate the class, it will try the `__Enum` method. When the error occurs, it will include the error information in the JSON stirng. Generally, when an error occurs, the object is not stringified and instead the placeholder is included. The exception is when iterating an object's `OwnProps()` method, in which case the error does not halt the process; only that specific property is skipped.

Regarding standard arrays, unset indices are handle by `Stringify`. These are represented by `""` in the string. Regarding maps, no error handling is built-in. It is expected that a map's items are enumerable, and so if an error occurs we will want to see the error.

### quoteNumbersAsKey

{Boolean}

When true, numbers are quoted when used as map keys. Example: `Map(500, "value)` becomes `[["500", "value"]]`. When false, the number is not quoted: `[[500, "value"]]`.

### escapeNL

{String}

The literal string of characters used to replace `r`n. When this option is set to empty or false, the characters are escaped by their usual counterpart. (i.e. "`r" is "\r" and "`n" is "\n"). When this option is set to a string, the literal string is used as a replacement for all matches with "\R"
[https://www.autohotkey.com/docs/v2/misc/RegEx-QuickRef.htm#Common](https://www.autohotkey.com/docs/v2/misc/RegEx-QuickRef.htm#Common)

### itemContainerArray
### itemContainerEnum
### itemContainerMap

{String}

These properties are used to assign a placeholder for items acquired from the `__Enum` method. The default values are `__ArrayItem`, `__MapItem`, and `__EnumItem`. This only has an effect when `useOwnProps` is `true` and the stringified objects have properties that are accessible by `Object.Prototype.OwnProps()` in its 1-parameter mode. When `Stringify` gets to the enumeration method, it assigns any items accessed from the enumeration method to this property. If the object already has the designted name, `Stringify` will append underscores to the name until a unique name is found.

# Details

This section is intended for those who may want to modify or adapt the script for other purposes. The core mechanisms employed by the function are described here.

## Tracker

`Stringify.Tracker` contains methods that enable the tracking of numbers and conditions that are necessry for the function's logic to work as expected. The most challenging component of this for me was enabling the use of formatting the formatting options, such as the line spacing and limits. I reworked the concept three times until landing on its present form, which works well and is not complicated once you know how it works.

`Tracker.prototype` will be referred to as simply `tracker`.

`tracker.currentIndent` tracks the current indent level. This is not modified by `tracker`. Instead, the `Stringify` function handles modifying the value. The reason this is the best approach is mostly because map objects require special indentation handling due to each item in the object having an extra open and close brace. Without this condition, `tracker` would have maintained complete control of indentation.

To enable the newline character count limit options, knowing the number of whitespace characters at a given segment of the JSON string is necessary. This is made a non-issue by the two properties `tracker.newline` and `tracker.indent`.

```ahk
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
```

`tracker.newline` and `tracker.indent` are properties that return the newline and indent strings, respectively. The newline string is returned only if the object is not a single line object. The indent string is returned only if the object is not a single line object and the current indent level is greater than 0. The newline string is a static value, and the indent string is a dynamic value that is modified by `Stringify` as needed.

```ahk
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
```

`ToggleSingleLine` is a function that toggles the single line flag on and off.

The parameter `on` is a boolean indicating whether the toggle is being activated or deactivated.

We use an integer value for `tracker.singleLineActive`, which was the superior choice to a boolean because we don't have to keep track of which conditions are activated where. Since the function recursion unto its child objects is linear, there's no worry of activation / deactivation events occurring out of order, but if we use a boolean value, we would have to keep track of this information manually. So instead, we increment and decrement as needed, and if `tracker.singleLineActive` is a positive value, then `tracker.newline` and `tracker.indent` know not to provide any whitespace.

`whichObj` is a string indicating the type of object that is calling the function, necessary only to know which option to compare values to.

`len` is the current string length at that moment, passed from `Stringify`.

When `_ResolveLen_()` is called, it calculates the difference between the current string length and the former string length, less any differences in whitespace, and then compares that to the limit imposed by the option value.

Tracking depth is straightforward, as the recursion is linear. `tracker.depth` is incremented and decremented when an object's journey into `Stringify` begins or ends, and either of the below functions are called. The extra logic including within `tracker.In()` performs these tasks:

- prevent infinite recursion
- enable the use of the option `newLineDepthLimit`
- signal to `Stringify` when the last recursion is ending, so it can unset the static variables `opt` and `tracker`

```ahk
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
    if !this.depth {    the function is completing is last (technically first) sequence and is about to end
        this.ToggleSingleLine(false, 'O', StrLen(str))
        for key, obj in this.tags
            obj.DeleteProp('__StringifyTag')
        this.parent.DeleteProp('__StringifyTag')
        return 1  we must direct `Stringify` to unset `tracker` so the next function cal
                    knows its a new call.
    }
    this.depth--
}
```

`tracker.In()` is called prior to an object being recursed into via `Stringify()`, and `tracker.Out()` is called as the process exits.

## Stringify

`Stringify` is the primary function that stringifies an object. It is a recursive function that iterates over an object's properties and values, and then calls itself on each value that is an object.

The stringification process begins with a switch function. Each object type, "Map", "Array", and "Object" has its own sequence of actions. I refactored the sequences as best I could into the current series of mini-functions. Any further refactoring would be trading one convenience for another hassle, and so this is where I found it best to stop.

There's significant asymmetry among the object type's different sequencs, which made the procedure difficult to balance with the configuration options. Finding the right location to add substrings to the primary string was a challenge, along with identifying the correct logic for controlling the newlines, indents, and brackets. Were I to do this again, I would first implement a debugging mechanism, as this would accomplish both making debugging easier, and laying the groundwork for the core tracking mechanism as well.

I used descriptive variable names, and so reading the function shouldn't be a problem, but I will highlight here the key areas to focus one's attention on when adusting the function.

- When making changes, it's best to take the time to map out what conditions influence the subject action / property. There is a healthy number of conditional flags in use with a degree of interconnectedness across sequences. I tried to be explicit where appropriate, such as using ByRef function parameters to explicitly indicate what is being modified by what function. But some information was best kept in the function scope rather than tied to a ByRef var.

- There are only two static variables in the scope, `tracker`, and `opt`, both of which are set anew with each function call. They must be unset prior to the completion of the function, or else the next function call will skip the `if !IsSet(tracker)` conditional segment.

- I used local variables at all times, unless the information is needed externally; in this case the variable is within the scope of `Stringify.Call()` (referred to here as simply `Stringify`).

- Comment out the broad try-catch blocks when debugging, as they can make it difficult to identify an error. They are necessary to allow the user to stringify any custom object without getting errors due to `Stringify` trying to access a property or method that does not have the right conditions to be accessed. But they are very broad and can hide code defects when implementing changes.

- Function `_MapProcess_()` gets its own function because it is accessed from two entry points. First, if the object passed to the function is an instance of Map. Second, if an object's enumeration sequence triggers the `flagAsMap` flag or the `enumAsMap` option is true. Within `_MapProcess_()`, `Stringify` attempts to enumerate the object using a basic `for` loop.

Let's dissect `_MapProcess_()`, as an example of how the logic is implemented.

## \_MapProcess\_

```ahk
_MapProcess_() {
    local isEmpty := 1, flag        ; set vars to local so not conflict with external vars
    _OwnProps_(true, 'M')           ; `_OwnProps_()` contains the sequence of actions that controls the object iterating over its own properties prior to invoking `__Enum()`. The function contains all the logic necessary to identify options and handle conditions. It is balanced for the script's current implementation, and updates might require changing the logic therein.
    for key, val in obj {           ; checking if the object is empty, so we don't add new lines and indents if it is empty
        if tracker.CheckIgnore(key)
            continue
        isEmpty := 0
        break
    }
    if isEmpty
        str .= '[]'
    else {
        tracker.ToggleSingleLine(true, 'M', StrLen(str)), _Open_(&str, '['), flag := 0      ; `tracker.ToggleSingleLine()` is a core component of the logic, and it handles all logic related to disabling then re-enabling the production of newlines and indent characters.
        for key, val in obj {
            if IsObject(key)                            ; During testing, I ran into a problem where a map's key was an object, and so I had to add this condition to prevent an error. The object likely implemented its own `__Enum` method, and this should be rare.
                key := '"{' _GetTypeString_(key) '}"'   ; `_GetTypeString_()` is a helper function to get the placeholders when needed
            if tracker.CheckIgnore(key)                 ; This checks the ignore list. Ignored properties do not get placeholders.
                continue
            _HandleNewItem_(&str, &flag), _Open_(&str, '['), _SetVal_(key, &str, opt.quoteNumbersAsKey), str .= ',' tracker.newline tracker.indent  ; This line has three actions. `_HandleNewItem_()` handles putting a comma between objects / items. `_Open_()` opens the bracket and increments the indent level. `_SetVal_()` sets the value to the string. `_SetVal_()` handles escaping characters that need escaped in JSON strings.
            _Process_(obj, &str, val, key), _Close_(&str, ']')  ; There are two actions here. `_Process_()` is the refactored sequence of actions that are shared by the three object types. `_Close_()` closes the bracket and decrements the indent level.
        }
        _Close_(&str, ']'), _SetSingleLine_(tracker.ToggleSingleLine(false, 'M', StrLen(str))), _OwnProps_(false, 'M')      ; There are three actions here. `_Close_()` is called again to close the outer bracket (since map objects are represented by arrays of size-two arrays, there is an outer bracket and a series of inner brackets). `_SetSingleLine_()` is a helper function that takes the output from `tracker.ToggleSingleLine()` and depending on the output, will remove all outer whitespace characters from this segment of the JSON string to turn it into a single-line. `_OwnProps_()` is called again to close the sequence of actions that control the object iterating over its own properties, primarily to determine if a closing brace is needed and if so, add it.
    }
}
```

As seen in the above code, the process functions set the series of actions and manage some conditional flags. Here's a list of functions and a short description of their purpose.

## Call

Implements a switch function to direct the flow of actions.

## OwnProps functions

\_PrepareOwnProps\_, \_OwnProps\_, \_EnumOwnProps\_

The functions that handle iterating an object's own properties.

The outer function, `_PrepareOwnProps_()`, was necessary to simplify handling the string values obtained from the rest of this sequence. We don't want to pass the main `str` variable to the function, because we don't know yet if the value obtained from the properties will be valid or needed. So we get a substring first, and check conditional flags to determine if the substring is going to be added to the string, or if it should be skipped. It also handles the indents and newlines as needed.

`_OwnProps_()` handles the opening and closing of the braces, and calling `tracker.ToggleSingleLine()`.

`_EnumOwnProps_()` iterates the object's properties.

## Process Functions

\_Process\_, \_Stringify\_, \_HandleNewItem\_

These functions contain actions shared by all of the sequences.

`_Process_()` is called for values. If the value is an object, and if `maxDepth` is a positive number and the current depth is equal to the value, a placeholder string is constructed. If `maxDepth` is not in use, or the depth is less, `_Stringify_()` is called. If the value is a number or string, `_SetVal_()` is called.

`_Stringify_()` identifies if an object is iterable. If not, a placeholder string is constructed. If it is, the object is recursed into with `Stringify()`

`_HandleNewItem_()` is called when a new item is being added to the string. It handles adding a comma between items.

## Setters

\_GetTypeString\_, \_Open\_, \_Close\_, \_GetItemPropName\_, \_SetVal\_, \_FormatError\_, \_SetSingleLine\_

Each of these functions, except `_SetSingleLine_()` handle the production of substrings.

`_SetSingleLine_()` handles the removal of external whitespace when reducing an object to a single line.
