# General Introduction

## Basics

You start a webpage with ```<!DOCTYPE html>``` following ```<html>``` and ending with ```</html>```. In those you can have ```<head>``` and ```<body>```
Then after that, you will have a ```<head>``` where you will put things that are not visible such as a script ```<script>``` and the ```<title>``` of a webpage
Following ```<head>``` you have ```<body>``` where you can put the actual content on your webpage.
Then you have different headings, up to 6, here they are:

```
<h1> Hello world!</h1>
<h2> Hello world!</h2>
<h3> Hello world!</h3>
<h4> Hello world!</h4>
```
etc.

Then you have paragraphs, where you can add and write text:
```<p> This is a paragraph where I will write a lot of information on many different things.</p>```

Then you have line breaks, the line you see across a page, you can access those with:
```<hr>```

Then after that you have newline (line break), which you can access with:
```<br>```

## HTML Attributes

```<a>``` defines a hyperlink, to specify where you want to go to you do:
```<a href="yourwebsite.com">The text for the link</a>```

```<img>``` adds an image, to specify from where you should get the image you do:
```<img src="/somethingsomething.png" alt="Something Something Image" width="500px" height="400px">```

To specify what the user sees when the image doesn't load for some reason, you add the alt (alternative text)

Next is the style attribute which allows you to add css styles inside an element.

```<p style="color: red">This is my long paragraph that's gonna be in red</p>```
<p style="color: red">This is my long paragraph that's gonna be in red as you can see</p>

The lang attribute should always be included in the ```<html>``` attribute, as search engines like that: ```<html lang="en">```

## Headings

Nothing new except that to change the font-size of a certain thing you should not make it ```<h1>``` just because of the size but you should use:

```<h4 style="font-size:300%">```

## Paragraphs

Nothing new except that HTML removes extra space meaning that if you want to display a poem or something pre-formated you should use:

```html
<pre>
This is my super cool text abc abc      extra space...
</pre>
```

## Styles

So you set the style either via a class or via style ```<p style="color: red"></p>```

- background-color sets the background color for that element: ```<p style="background-color:powderblue"> Hi, hello</p>```

- color sets the background color for the text in an element: ```<p style="color:red">Hi, hello it's me myself and I</p>```

- font family sets the font to be used in that element: <p style="font-family:courier;">This is a paragraph.</p>
```<p style="font-family:courier;">This is a paragraph.</p>```

- text-size is used to set the text-size ```<p style="text-size=300%">HI</p>```

- text-align sets the alignment for the text in a certain element

<p style="text-align:center;">Centered paragraph.</p>

```<p style="text-align:center;">Centered paragraph.</p>```

## Text formatting

```
<b> - Bold text
<strong> - Important text
<i> - Italic text
<em> - Emphasized text
<mark> - Marked text
<small> - Smaller text
<del> - Deleted text
<ins> - Inserted text
<sub> - Subscript text
<sup> - Superscript text
```

<b> - Bold text </b>

<strong> - Important text </strong>

<i> - Italic text </i>

<em> - Emphasized text </em>

<mark> - Marked text </mark>

<small> - Smaller text </small>

<del> - Deleted text </del>

<ins> - Inserted text </ins>

<sub> - Subscript text </sub>

<sup> - Superscript text </sup>

<p>This is for my chemistry text boi</p>
<p>H<sub>2</sub>O + H<sub>3</sub>COOH <-> (H<sub>2</sub>O)<sup>5</sup>


<mark> I should learn this for my test </mark>

## Quotation

- blockquote is for longer quotations, browsers will usually indent those

```<blockquote cite="wwf.org"> For 100 years bla bla </blockquote> ```

- q is for short quotes:

```<p> My father used to say frequently: <q>GET UP YOU LAZY ASS</q></p>```
<p> My father used to say frequently: <q>GET UP YOU LAZY ASS</q></p>

- abbr is for abbreviations or acronyms:
<p>The <abbr title="Holy Reverant Father">HRF</abbr> is a very important person</p>

```<p>The <abbr title="Holy Reverant Father">HRF</abbr> is a very important person</p>```

- address is for contact information to the writer:
<address>
Written by John Doe.<br>
Visit us at:<br>
Example.com<br>
Box 564, Disneyland<br>
USA
</address>


```html
<address>
Written by John Doe.<br>
Visit us at:<br>
Example.com<br>
Box 564, Disneyland<br>
USA
</address>
```

- The HTML ```<cite>``` tag defines the title of a creative work
<p><cite>The Scream</cite> by Edvard Munch. Painted in 1893.</p>

```<p><cite>The Scream</cite> by Edvard Munch. Painted in 1893.</p>```

- The HTML ```<bdo>``` for by-directional override

```<bdo dir="rtl">This text will be written from right to left</bdo>```

<bdo dir="rtl">This text will be written from right to left</bdo>

## HTML Colors

- To set the background color of elements you use:

```<h1 style="background-color:red">hi</h1>```

- To set text color you use

```<h1 style="color: red">hi</h1>```

- To set the border color you use

```<h1 style="border:2px color Tomato">hi</h1>```

## CSS

Cascading Style Sheets (CSS) are used to control what the webpage looks like (color, size, etc. etc.)

You can use css in 3 ways

- In the element by using style="etc.etc"
- In the head section using ```<style>```
- In a seperate file by using ```<link>```

Example using css in the head section

```html
<!DOCTYPE html>
<html>
<head>
<style>
body {background-color: powderblue;}
h1   {color: blue;}
p    {color: red;}
</style>
</head>
<body>

<h1>This is a heading</h1>
<p>This is a paragraph.</p>

</body>
</html>
```

Example using seperate file (most used because easiest to manage)

```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="styles.css">
</head>
<body>

<h1>This is a heading</h1>
<p>This is a paragraph.</p>

</body>
</html>
```

- The CSS color property defines the text color to be used.

- The CSS font-family property defines the font to be used.

- The CSS font-size property defines the text size to be used.

- The CSS border property defines a border around an HTML element.

- The CSS padding property defines a padding (space) between the text and the border.

- The CSS margin property defines a margin (space) outside the border.

## HTML Links

Basic syntax is:

```<a href="url">link text</a>```

<a href="url">link text</a>

The target attribute specifies where to open the linked document.

The target attribute can have one of the following values:

_self - Default. Opens the document in the same window/tab as it was clicked

_blank - Opens the document in a new window or tab

_parent - Opens the document in the parent frame

_top - Opens the document in the full body of the window

To use an iamge as a link we just need to put the  ```<img>``` tag inside the ```<a>``` tag

We use mailto: to specify to who to send a link
```<a href="mailto:someone@example.com">Send email</a>```

JavaScript allows you to specify what happens at certain events, such as a click of a button:

```<button onclick="document.location='www.google.com'">HTML Tutorial</button>```

The title attribute shows a tooltip inside the browser

<a href="https://www.google.com/html/" title="Go to W3Schools HTML section">Visit our HTML Tutorial</a>


We can turn off the underline in a link when you hover it with the following CSS:

text-decoration: none;

## Bookmarking on a page

When a page is long it's handy to add bookmarks so that a user can immediately go down to that place, we can do this with the attribute id

```<h2 id="C4">Chapter 4</h2>```

```<a href="#C4">Jump to Chapter 4</a>```