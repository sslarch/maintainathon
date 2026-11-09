-- Builds the reading list from reading/themes.json and reading/entries/*.json at render time.
-- reading.qmd lists this file under `filters` and holds a Div with id "reading-list-here",
-- which this filter replaces with the generated HTML.

local here = (PANDOC_SCRIPT_FILE or ""):match("^(.*)[/\\][^/\\]*$") or "."
local REQUIRED = { "entrytype", "author", "title", "date", "keywords" }
local FIELD_ORDER = {
  "author", "editor", "title", "subtitle", "journaltitle", "booktitle", "series", "publisher",
  "location", "edition", "date", "volume", "number", "pages", "doi", "isbn", "issn", "url",
  "urldate", "keywords", "abstract", "note",
}
local rank = {}
for i, name in ipairs(FIELD_ORDER) do rank[name] = i end

local function fail(message)
  error(message, 0)
end

local function read(path)
  local file = io.open(path, "rb")
  if not file then fail("cannot open " .. path) end
  local text = file:read("a")
  file:close()
  return text
end

local function load_json(path, name)
  local ok, value = pcall(pandoc.json.decode, read(path), false)
  if not ok then fail(name .. ": invalid JSON (" .. tostring(value) .. ")") end
  return value
end

local function esc(s)
  return (s:gsub("[&<>\"']", {
    ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&#x27;",
  }))
end

-- Escapes the characters LaTeX reads as commands; doi and url are verbatim fields.
local function latex(name, value)
  if name == "doi" or name == "url" then return value end
  return (value:gsub("(\\?)([&%%$#_])", function(slash, char)
    if slash == "" then return "\\" .. char end
  end))
end

local function split_authors(text)
  local names, pos = {}, 1
  while true do
    local from, to = text:find(" and ", pos, true)
    if not from then
      names[#names + 1] = text:sub(pos)
      return names
    end
    names[#names + 1] = text:sub(pos, from - 1)
    pos = to + 1
  end
end

local function tighten(name)
  local count
  repeat name, count = name:gsub("(%u%.)%s+(%u%.)", "%1%2") until count == 0
  return name
end

local function meta_authors(entry)
  local names = split_authors(entry.author)
  for i, name in ipairs(names) do names[i] = tighten(name) end
  local last = table.remove(names)
  if last == "others" then return table.concat(names, ", ") .. " et al." end
  if #names == 0 then return last end
  return table.concat(names, ", ") .. " and " .. last
end

local function cite_authors(entry)
  local names = split_authors(entry.author)
  local last = table.remove(names)
  if last == "others" then return table.concat(names, ", ") .. ", et al." end
  if #names == 0 then return last end
  return table.concat(names, ", ") .. ", & " .. last
end

local function stop(text)
  if text:sub(-1):match("[%.%?!]") then return text end
  return text .. "."
end

local function link_of(entry)
  if entry.doi then return "https://doi.org/" .. entry.doi end
  return entry.url
end

local function meta_line(entry)
  local venue
  if entry.journaltitle then
    venue = entry.journaltitle
    if entry.volume then
      venue = venue .. " " .. entry.volume
      if entry.number then venue = venue .. "(" .. entry.number .. ")" end
    end
  else
    local parts = {}
    for _, name in ipairs({ "booktitle", "publisher" }) do
      if entry[name] then parts[#parts + 1] = entry[name] end
    end
    venue = table.concat(parts, ", ")
  end
  return esc(meta_authors(entry) .. " (" .. entry.date:sub(1, 4) .. "). " .. venue)
end

local function citation(entry)
  local parts = { esc(cite_authors(entry)) .. " (" .. entry.date:sub(1, 4) .. ")." }
  local title = esc(entry.title)
  if entry.journaltitle then
    local tail = "<em>" .. esc(entry.journaltitle) .. "</em>"
    if entry.volume then
      tail = tail .. ", <em>" .. esc(entry.volume) .. "</em>"
      if entry.number then tail = tail .. "(" .. esc(entry.number) .. ")" end
    end
    parts[#parts + 1] = stop(title)
    parts[#parts + 1] = stop(tail)
  elseif entry.booktitle then
    parts[#parts + 1] = stop(title)
    parts[#parts + 1] = stop("In <em>" .. esc(entry.booktitle) .. "</em>")
    if entry.publisher then parts[#parts + 1] = stop(esc(entry.publisher)) end
  else
    parts[#parts + 1] = stop("<em>" .. title .. "</em>")
    if entry.publisher then parts[#parts + 1] = stop(esc(entry.publisher)) end
  end
  local url = link_of(entry)
  if url then
    parts[#parts + 1] = '<a href="' .. esc(url) .. '" target="_blank" rel="noopener noreferrer">' .. esc(url) .. "</a>"
  end
  return table.concat(parts, " ")
end

local function biblatex(key, entry)
  local names = {}
  for name in pairs(entry) do
    if name ~= "entrytype" then names[#names + 1] = name end
  end
  table.sort(names, function(a, b)
    local ra, rb = rank[a] or (#FIELD_ORDER + 1), rank[b] or (#FIELD_ORDER + 1)
    if ra ~= rb then return ra < rb end
    return a < b
  end)
  local lines = {}
  for _, name in ipairs(names) do
    local rows = {}
    for row in (latex(name, entry[name]) .. "\n"):gmatch("(.-)\n") do rows[#rows + 1] = row end
    for i = 2, #rows do
      if rows[i] ~= "" then rows[i] = "  " .. rows[i] end
    end
    lines[#lines + 1] = "  " .. name .. " = {" .. table.concat(rows, "\n") .. "}"
  end
  return "@" .. entry.entrytype .. "{" .. key .. ",\n" .. table.concat(lines, ",\n") .. "\n}"
end

local function button(label, view)
  return '<button type="button" class="small" aria-expanded="false" onclick="readingToggle(this,\''
    .. view .. '\')">' .. label .. "</button>"
end

local function render(key, entry, theme)
  local url = link_of(entry)
  local out = { '<li data-theme="' .. theme.id .. '">' }
  out[#out + 1] = '<span class="reading-theme"><span class="dot" style="background:' .. theme.color
    .. '"></span>' .. esc(theme.label) .. "</span>"
  out[#out + 1] = '<h2 class="reading-title">' .. esc(entry.title) .. "</h2>"
  out[#out + 1] = '<p class="reading-meta">' .. meta_line(entry) .. "</p>"
  if url then
    out[#out + 1] = '<a class="reading-link" href="' .. esc(url)
      .. '" target="_blank" rel="noopener noreferrer">' .. esc(url:gsub("^https?://", "")) .. "</a>"
  end
  out[#out + 1] = '<div class="reading-actions">'
  if entry.abstract then out[#out + 1] = button("Abstract", "abs") end
  out[#out + 1] = button("BibLaTeX", "bib")
  out[#out + 1] = button("Cite", "cite")
  out[#out + 1] = "</div>"
  out[#out + 1] = '<div class="reading-panel" data-view="abs" hidden>'
  if entry.abstract then
    out[#out + 1] = '<div class="view-abs"><p class="label">Abstract <button type="button" class="copy" '
      .. 'onclick="readingCopy(this,\'.body\')">Copy</button></p><p class="body">'
      .. esc(entry.abstract) .. "</p></div>"
  end
  out[#out + 1] = '<div class="view-bib"><p class="label">BibLaTeX <button type="button" class="copy" '
    .. 'onclick="readingCopy(this,\'pre\')">Copy</button></p><pre>' .. esc(biblatex(key, entry)) .. "</pre></div>"
  out[#out + 1] = '<div class="view-cite"><p class="label">Citation <button type="button" class="copy" '
    .. 'onclick="readingCopy(this,\'.citation\')">Copy</button></p><p class="citation">'
    .. citation(entry) .. "</p></div>"
  out[#out + 1] = "</div>"
  out[#out + 1] = "</li>"
  return table.concat(out, "\n")
end

local function build()
  local themes = load_json(here .. "/themes.json", "themes.json")
  local theme_by_label, theme_order = {}, {}
  for i, theme in ipairs(themes) do
    theme_by_label[theme.label] = theme
    theme_order[theme.label] = i
  end

  local entries = {}
  local files = pandoc.system.list_directory(here .. "/entries")
  table.sort(files)
  for _, file in ipairs(files) do
    if file:match("%.json$") then
      local entry = load_json(here .. "/entries/" .. file, file)
      if type(entry) ~= "table" then fail(file .. ": expected a JSON object") end
      for name, value in pairs(entry) do
        if type(value) == "number" then
          entry[name] = string.format("%.15g", value)
        elseif type(value) ~= "string" then
          fail(file .. ": '" .. name .. "' must be text")
        end
      end
      local missing = {}
      for _, name in ipairs(REQUIRED) do
        if entry[name] == nil then missing[#missing + 1] = name end
      end
      if #missing > 0 then fail(file .. ": missing " .. table.concat(missing, ", ")) end
      if not theme_by_label[entry.keywords] then
        fail(file .. ": keywords '" .. entry.keywords .. "' match no label in themes.json")
      end
      entries[#entries + 1] = { key = file:gsub("%.json$", ""), entry = entry }
    end
  end

  local function first_surname(entry)
    return pandoc.text.lower(split_authors(entry.author)[1]:match("^([^,]*)"))
  end
  table.sort(entries, function(a, b)
    local ta, tb = theme_order[a.entry.keywords], theme_order[b.entry.keywords]
    if ta ~= tb then return ta < tb end
    local sa, sb = first_surname(a.entry), first_surname(b.entry)
    if sa ~= sb then return sa < sb end
    if a.entry.date ~= b.entry.date then return a.entry.date < b.entry.date end
    return a.key < b.key
  end)

  local counts = {}
  for _, item in ipairs(entries) do
    counts[item.entry.keywords] = (counts[item.entry.keywords] or 0) + 1
  end

  local page = {
    '<a class="reading-download" href="#" download="references.bib" onclick="readingDownload(this)">Download BibLaTeX</a>',
    '<div class="reading-chips">',
    '<button type="button" class="chip on" data-theme="all" onclick="readingFilter(this)">All <span>'
      .. #entries .. "</span></button>",
  }
  for _, theme in ipairs(themes) do
    if counts[theme.label] then
      page[#page + 1] = '<button type="button" class="chip" data-theme="' .. theme.id
        .. '" onclick="readingFilter(this)">' .. esc(theme.label) .. " <span>" .. counts[theme.label] .. "</span></button>"
    end
  end
  page[#page + 1] = "</div>"
  page[#page + 1] = '<ul class="reading-list" id="reading-list">'
  for _, item in ipairs(entries) do
    page[#page + 1] = render(item.key, item.entry, theme_by_label[item.entry.keywords])
  end
  page[#page + 1] = "</ul>"
  return table.concat(page, "\n")
end

function Div(el)
  if el.identifier == "reading-list-here" then
    return pandoc.RawBlock("html", build())
  end
end