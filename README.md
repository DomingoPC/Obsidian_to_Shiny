# Sharing Obsidian Notes with a Shiny Website App

[Obsidian](https://obsidian.md) is a powerful note-taking app that emphasizes dynamic connections between documents over traditional folder hierarchies. While this structure is liberating for writing, it can be difficult to share your work unless you use Obsidian's paid publishing services. However, this limitation also highlights the potential to build your own website to host and share your notes. This project explores the steps I followed to do just that:

1. **Extract Document Metadata**: Metadata includes *tags*, used to group documents under specific categories, and *connections*, used to build a graph-like structure.

2. **Parse Documents**: After extracting metadata, tag syntax (`#tag`) and link syntax (`[[connection]]`) are removed or transformed to improve readability.

3. **Create a Website**: This is the most complex step, involving rendering Markdown files and visualizing document connections with an interactive graph.

There are several ways to achieve this, and I chose to use **R** because it can handle all steps natively: the first two are easily handled with regular expressions, and the final step is accomplished with **Shiny**, which translates R code into interactive JavaScript components.

---

## Document Preprocessing

Extracting metadata is necessary for building the graph and must be done before website launch. Parsing documents for readability can happen on demand when the document is loaded, but since the process is fast and repeatable, it made more sense to preprocess everything locally. This approach reduces the load on the server and speeds up interaction for users.

Here’s an overview of the preprocessing workflow for each document:

- Read the document line by line.
- Identify `#tags`, add them to the document’s tag list, and remove them from the content.
- Identify `[[connection]]` or `[[connection|display name]]`, store the connection in the document’s link list, and replace the original syntax with a clickable link (technically handled via JavaScript to trigger a custom event).
- Save the cleaned version of the document to the website folder (`www/documents`).

Additionally, I assigned two special tags to improve navigation and categorization:

- **No tag**: For documents that have no tags.
- **Not written**: For documents that are only referenced via connections but don’t yet exist. This is a common pattern in Obsidian, used to sketch out future notes and enhance graph complexity.

---

## Building a Website with Shiny

The core functionality of the Shiny app relies heavily on the `observeEvent()` function, which allows the interface to react to user interactions like clicks or selections. Once this reactive behavior is in place, the rest is about creating useful features. Since there’s no folder structure to rely on, I focused on offering multiple entry points to access the documents:

- A **"Select Document"** dropdown in the sidebar shows available documents and updates dynamically based on user actions.
- Sidebar filters for custom tags like **Planets**, **Species**, and **Sources**. Clicking a tag shows related documents, and selecting one updates the dropdown.
- Within each document, connections appear as clickable links that also update the dropdown and load the selected document.
- In the **graph section**, clicking on a node highlights a document. You can then load it using the **"Go to Selected Document"** button.

### Additional Features:

- An **interactive graph**: Helps visualize the network of documents. Nodes can be clicked and dragged around for better exploration.
- A **download button** below the document selector: Lets users download the current document as an HTML file.

---

## Publishing the Shiny App

The easiest way to publish a Shiny app is via [shinyapps.io](https://www.shinyapps.io/), which provides a generous free tier—ideal for projects with low traffic. You can explore the final result here:  
👉 [**Magic Systems**](https://domingopc.shinyapps.io/magic_system__Domingo/)
