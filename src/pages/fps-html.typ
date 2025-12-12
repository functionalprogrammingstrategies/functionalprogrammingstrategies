
#import "stdlib.typ": title, authors

#set document(
    title: title,
    author: authors
)

// Default styling

#set text(font: "EB Garamond", size: 12pt)

#show raw.where(block: true): set block(fill: rgb("F7F7F7"), inset: 8pt, width: 100%)
#show raw.where(block: true): set text(size: 8pt)

// Table styling
#set table(
    inset: 8pt,
    stroke: (_, y) => if y >= 0 { (top: 0.8pt) }
)
#show table.cell: set align(start)
#show table.cell.where(y: 0): set text(weight: "bold")


// Front matter
#include "parts/frontmatter.typ"

// Main matter
#show link: set text(rgb("#996666"))

#pagebreak(to: "odd")
#set page(numbering: "1")
#set heading(numbering: "1.")
#counter(page).update(1)
#counter(heading).update(0)

// The main matter is organized into parts
// Start parts on an odd page
#show figure.where(kind: "part"): it => {
    pagebreak(weak: true, to: "odd")
    set text(
        font: "Lato",
        size: 12pt * 1.333 * 1.333 * 1.333
    )
    align(left)[
        #strong[#it.supplement #it.counter.display(it.numbering): #it.body]
    ]
}
#show heading.where(level: 1): it => {
    // Chapter heading starts on an odd page. Don't create a page break if the
    // page is already empty.
    pagebreak(weak: true, to: "odd")
    set text(
        font: "Lato",
        size: 12pt * 1.333 * 1.333 * 1.333)
    it
    v(12pt * 1.333)
}
#show heading.where(level: 2): it => {
    v(12pt)
    set text(
        font: "Lato",
        size: 12pt * 1.333 * 1.333)
    it
    v(12pt * 1.333)
}
#show heading.where(level: 3): it => {
    v(12pt / 1.2)
    set text(
        font: "Lato",
        size: 12pt * 1.333)
    it
    v(12pt)
}
#show heading.where(level: 4): it => {
    v(12pt / 1.2 / 1.2)
    set text(
        font: "Lato",
        size: 12pt)
    it
    v(12pt)
}

#include "toc.typ"
