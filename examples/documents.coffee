# Document Model
dc.model.Document: dc.Model.extend({

  constructor: attributes => this.base(attributes)

  # For display, show either the highlighted search results, or the summary,
  # if no highlights are available.
  # The import process will take care of this in the future, but the inline
  # version of the summary has all runs of whitespace squeezed out.
  displaySummary: =>
    text: this.get('highlight') or this.get('summary') or ''
    text and text.replace(/\s+/g, ' ')

  # Return a list of the document's metadata. Think about caching this on the
  # document by binding to Metadata, instead of on-the-fly.
  metadata: =>
    docId: this.id
    _.select(Metadata.models(), (meta =>
      _.any(meta.get('instances'), instance =>
        instance.document_id is docId)))

  bookmark: pageNumber =>
    bookmark: new dc.model.Bookmark({title: this.get('title'), page_number: pageNumber, document_id: this.id})
    Bookmarks.create(bookmark)

  # Inspect.
  toString: => 'Document ' + this.id + ' "' + this.get('title') + '"'

})

# Document Set
dc.model.DocumentSet: dc.model.RESTfulSet.extend({

  resource: 'documents'

  SELECTION_CHANGED: 'documents:selection_changed'

  constructor: options =>
    this.base(options)
    _.bindAll(this, 'downloadSelectedViewers', 'downloadSelectedPDF', 'downloadSelectedFullText')

  selected: => _.select(this.models(), m => m.get('selected'))

  selectedIds: => _.pluck(this.selected(), 'id')

  countSelected: => this.selected().length

  downloadSelectedViewers: =>
    dc.app.download('/download/' + this.selectedIds().join('/') + '/document_viewer.zip')

  downloadSelectedPDF: =>
    if this.countSelected() <= 1 then return window.open(this.selected()[0].get('pdf_url'))
    dc.app.download('/download/' + this.selectedIds().join('/') + '/document_pdfs.zip')

  downloadSelectedFullText: =>
    if this.countSelected() <= 1 then return window.open(this.selected()[0].get('full_text_url'))
    dc.app.download('/download/' + this.selectedIds().join('/') + '/document_text.zip')

  # We override "_onModelEvent" to fire selection changed events when documents
  # change their selected state.
  _onModelEvent: e, model =>
    this.base(e, model)
    fire: e is dc.Model.CHANGED and model.hasChanged('selected')
    if fire then _.defer(_(this.fire).bind(this, this.SELECTION_CHANGED, this))

})

# The main set of Documents, used by the search tab.
window.Documents: new dc.model.DocumentSet()

# The set of documents that is used to look at a particular label.
dc.app.LabeledDocuments: new dc.model.DocumentSet()
