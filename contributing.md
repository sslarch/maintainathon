# Contributing

This site holds a set of resources pages and a reading list for people who maintain archaeological software. Anyone can add to them. This guide explains how each one is built so that pages and entries written by different people read as one collection.

Contributions must follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Repository structure

- `resources/*.qmd` holds one resources page per file.
- `reading/entries/*.json` holds one reading list entry per file.
- `reading/themes.json` holds the themes that group reading list entries.
- `reading/list.lua` builds the reading list from those files. You never need to edit it.
- `images/` holds the images that pages use.

## How to contribute

You can edit a file on GitHub with the pencil icon, or fork the repository, work on your computer, and open a pull request. Both routes end with a maintainer reviewing a pull request.

Keep each pull request to one reading list entry or one resources page. Small pull requests get reviewed faster and rarely conflict with each other. Open an [issue](https://github.com/sslarch/maintainathon/issues) before a large change such as a new theme, a new category or a restructured page.

To preview your work, install [Quarto](https://quarto.org/docs/get-started/) and run `quarto preview` from the repository root. Then open <http://localhost:7777> in your browser.

## Resources pages

Each resources page is one `.qmd` file in `resources/`. Never edit `resources/index.qmd`. A new page is added to the resources listing automatically.

### Add a page

Copy this template into a new file in `resources/`.

```yaml
---
title: "Verb the thing"
description: "One sentence that tells a newcomer what they get from this page."
categories: [Technical]
---

Opening paragraph that says what the topic is and why it matters when you maintain archaeological software.

A second paragraph that tells the reader what to do first.

## A heading for the main task

1. First action.
2. Second action.

## Further reading

- [Descriptive link text](https://example.org/permalink)
```

Name the file after the title, in lowercase, with hyphens and the verb first, such as `write-a-better-readme.qmd`.

| Front matter | Notes |
| ---- | ------------ |
| `title` | Sentence case, in quotation marks, beginning with a verb, as in "Test your code". |
| `description` | One sentence that ends with a period. It appears on the resources card. |
| `categories` | One existing category. Current categories are Technical, Community, Preserve and release, Document and Plan. |
| `order` | Leave it out unless a maintainer asks for a fixed position in the listing. |

Open with one or two paragraphs that say what the topic is and why it matters. Follow with the steps or the worked example. End with a `## Further reading` list of links. Put code in fenced blocks that name the language, such as `r` or `python`. Store images in `images/`, link them as `../images/name.png`, and describe each one in the alt text.

### Maintaining a page

Check that the links on a page still open whenever you edit it, and replace a dead link with an archived copy. Update instructions, screenshots and code when the tool they describe changes.

Delete a page by deleting its file. Then search the repository for the file name and remove the links that point to it.

## Reading list entries

Each entry is one JSON file in `reading/entries/`. When the site builds, it reads every file in that folder, sorts the entries by theme, first author and date, and generates the Abstract, BibLaTeX and Cite buttons for each one. You never edit `reading.qmd` or `reading/list.lua` to add an entry.

### Add an entry

Copy this template into a new file in `reading/entries/`.

```json
{
  "entrytype": "article",
  "author": "Surname, A. B. and Surname, C.",
  "title": "Title of the work in sentence case",
  "journaltitle": "Name of the journal",
  "date": "2024",
  "volume": "12",
  "number": "3",
  "doi": "10.0000/example",
  "keywords": "Research software engineering",
  "abstract": "First paragraph of the abstract.\n\nSecond paragraph, if there is one."
}
```

Name the file after the first author's surname and the year, in lowercase with no spaces or accents, such as `wilson2017.json`. Add a letter when two entries collide, such as `wilson2017a.json`. The file name becomes the citation key in the BibLaTeX record.

Replace the placeholder values and delete the optional fields that do not apply to your entry.

Every entry needs these five fields.

| Field | Notes |
| ---- | ------------ |
| `entrytype` | The BibLaTeX entry type. The list uses `article`, `book` and `inproceedings`. |
| `author` | `Surname, Initials`, with `and` between authors. Write `and others` to shorten a long author list. |
| `title` | Sentence case, as the existing entries use. |
| `date` | A year such as `2017`, or a full date such as `2017-06-22`. The page shows the year. |
| `keywords` | The theme. Copy one label exactly from `themes.json`. |

Add the optional fields that fit your entry.

| Field | Notes |
| ---- | ------------ |
| `journaltitle` | The journal name for an article. |
| `volume` | Shown after the journal name. |
| `number` | Shown after the volume. |
| `booktitle` | The proceedings or book title for a conference paper. |
| `publisher` | The publisher of a book or conference paper. |
| `doi` | The DOI alone, without the web address. The page links to it. |
| `url` | Used for the link when the entry has no DOI. |
| `abstract` | The Abstract button appears only when this field exists. |

Any other BibLaTeX field, such as `pages`, `location` or `isbn`, goes into the BibLaTeX record when you add it.

JSON is strict about a few things.

- Write every value as text in double quotes, numbers included, as in `"volume": "12"`.
- Type special characters as they appear. The BibLaTeX record escapes `&`, `%`, `$`, `#` and `_` for you.
- Escape a double quote inside a value with a backslash (`\"`), and write a paragraph break in an abstract as `\n\n`.
- Leave no comma after the last field.

### Choose a theme

The `keywords` field places the entry under a theme. Copy the label exactly from `reading/themes.json`. The current labels are listed here.

- Research software engineering
- Archaeological software development
- Culture and history of FOSS

### Add a theme

Add an object to `reading/themes.json` in the position where the theme should appear. The order of the file sets the order of the buttons and sections on the page. A theme with no entries stays hidden.

```json
{"id": "short-id", "label": "Name shown on the page", "color": "#2B6C8F"}
```

### Fix or retire an entry

Edit the file to correct a field. Delete the file to remove the entry. Renaming the file changes the citation key in the BibLaTeX record.

### Fix a build error

When an entry has a problem, the build stops and names the file, as in `wilson2017.json: missing date`. The rest of the message says what to fix.

- `invalid JSON` points to a missing comma, a comma after the last field, or a value without quotes.
- `expected a JSON object` means the file must start with `{` and end with `}`.
- `missing author, date` lists the fields to add.
- `'volume' must be text` means the value needs double quotes.
- A message about `keywords` means the theme is spelled differently from the labels in `reading/themes.json`, or does not exist yet. Fix the spelling or add the theme.

## Style preferences

These are preferences, not rules. They are meant to help pages and entries read as one collection.

- Write headings in sentence case.
- Write in plain, direct language, address the reader as "you", and use the imperative for steps.
- Keep each paragraph to one idea.
- Use descriptive link text, such as "Getting started with testing in Python".
- Define jargon the first time it appears.
- Link to a clean permalink when one is available, such as a DOI link or an archived copy, over a long or session-specific URL.

## Practical tips

- Copy a nearby file as a model for structure and tone.
- Preview your work with `quarto preview` before you open a pull request.
- Copy a reading list entry's author names, title and DOI from the publisher's page or the DOI record so they match the published version.
- Open the BibLaTeX panel on your new entry in the preview and check that the record looks complete.
- Describe in the pull request what you added and why.
- Ask in an issue when something in this guide is unclear.