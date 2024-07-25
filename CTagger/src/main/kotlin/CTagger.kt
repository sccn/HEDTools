import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.google.gson.internal.LinkedTreeMap
import com.google.gson.reflect.TypeToken
import com.univocity.parsers.tsv.TsvParser
import com.univocity.parsers.tsv.TsvParserSettings
import model.*
import java.awt.*
import java.awt.event.WindowAdapter
import java.awt.event.WindowEvent
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.io.StringReader
import java.lang.reflect.Type
import java.net.URL
import javax.swing.*
import javax.swing.border.EmptyBorder
import javax.xml.bind.JAXBContext
import kotlin.system.exitProcess


fun main() {
    SwingUtilities.invokeLater { CTagger(isJson = false, isTSV = false, filename = "", jsonString="", isScratch=true) }
}

class CTagger(
    var isStandalone: Boolean = true,
    val isJson: Boolean,
    var isTSV: Boolean,
    var filename: String,
    var jsonString: String,
    var isScratch: Boolean
) {
    var isVerbose = false
    var loader: TaggerLoader? = null
    private val frame = JFrame("CTagger v3.4.0")
    var hedVersion = ""
    lateinit var unitClasses: Set<UnitClassXmlModel>
    lateinit var unitModifiers: ArrayList<UnitModifierXmlModel>
    val tags = mutableListOf<String>()
    val schema = HashMap<String, TagModel>()
    private lateinit var hedValidator: HedValidator
    val fieldList = FieldList(this)
    var eventCodeList: EventCodeList
    private lateinit var schemaView: SchemaView
    lateinit var inputPane: InputLayeredPane
    private var centerPane = JPanel()
    private var validationStatus = JLabel("No annotation")
    private val validator = HEDWebService()
    var isValidated = true
        set(value) {
            if (value)
                validationStatus.text = "Validated"
            else
                validationStatus.text = "Unvalidated"
            field = value
            hideSearchResultPane()
        }

    init {
        getHedXmlModel()
        eventCodeList = EventCodeList(this)

        frame.setSize(1000, 800)
        if (isStandalone)
            frame.defaultCloseOperation = JFrame.EXIT_ON_CLOSE
        else
            frame.defaultCloseOperation = JFrame.DISPOSE_ON_CLOSE
        frame.addWindowListener(object : WindowAdapter() {
            override fun windowClosing(evt: WindowEvent?) {
                if (!isStandalone) {
                    loader!!.notified = true
                    loader!!.canceled = true
                }
            }
        })
        val dim = Toolkit.getDefaultToolkit().screenSize
        frame.setLocation(dim.width / 2 - frame.size.width / 2, dim.height / 2 - frame.size.height / 2)


        val mainPane = frame.contentPane
        mainPane.layout = BorderLayout()

        createMenuBar()
        addFieldSelectionPane(mainPane)
        addCenterPane(mainPane)
        addBtnPane(mainPane)

//        hedTagInput.setNoParsing()
        if (isTSV)
            importBIDSEventTSV(File(filename))
        else if (isJson)
            if (filename.isEmpty() && jsonString.isNotEmpty())
                importBIDSEventJson(jsonString)
            else
                importBIDSEventJson(File(filename))
        else {
            isScratch = true
            importBIDSEventJson("{'none': {}}")
        }
//        hedTagInput.setParsing()

        // set default background color to all panels and dialogs
        UIManager.put("Panel.background", Style.BLUE_MEDIUM)
        UIManager.put("OptionPane.background", Style.BLUE_MEDIUM)
        SwingUtilities.updateComponentTreeUI(frame)
        frame.pack()
        frame.isResizable = false
        frame.isVisible = true

        // start saving thread
//        timer(name = "Save tags", period = 500) {
//            if (isVerbose) println("Saving tags")
//            // save current tags
//        }
    }

    private fun createMenuBar() {
        val menuBar = JMenuBar()

        // File menu item
        var menu = JMenu("File")
        menuBar.add(menu)

        // Import event file menu item
        var submenu = JMenu("Import")
        var menuItem = JMenuItem("Import annotation spreadsheet")
        menuItem.addActionListener {
            val fc = JFileChooser()
            val fileChosen = fc.showOpenDialog(frame)
            if (fileChosen == JFileChooser.APPROVE_OPTION) {
                val file = fc.selectedFile
                importSpreadsheet(file)
            }
        }
        submenu.add(menuItem)

        menuItem = JMenuItem("Import BIDS events.tsv file")
        menuItem.addActionListener {
            val fc = JFileChooser()
            val fileChosen = fc.showOpenDialog(frame)
            if (fileChosen == JFileChooser.APPROVE_OPTION) {
                val file = fc.selectedFile
                importBIDSEventTSV(file)
            }
        }
        submenu.add(menuItem)

        menuItem = JMenuItem("Import BIDS events.json file")
        menuItem.addActionListener {
            val fc = JFileChooser()
            val fileChosen = fc.showOpenDialog(frame)
            if (fileChosen == JFileChooser.APPROVE_OPTION) {
                val file = fc.selectedFile
                importBIDSEventJson(file)
            }
        }
        submenu.add(menuItem)
        menu.add(submenu)

        menuItem = JMenuItem("Change schema version")
        menuItem.addActionListener {
            val schemaList = URL("https://api.github.com/repos/hed-standard/hed-specification/contents/hedxml").readText()
            val sType = object : TypeToken<Array<SchemaListObject>>() { }.type
            val listObject: Array<SchemaListObject> = Gson().fromJson(schemaList, sType)
            val hedVersions =mutableListOf<String>()
            listObject.forEach{ if (it.name.contains("xml")) hedVersions.add(it.name.replace(".xml","")) }
            val selection = JOptionPane.showInputDialog(frame, "Choose new schema version:", "", JOptionPane.PLAIN_MESSAGE, null, hedVersions.toTypedArray(), "HEDLatest")
            if (selection != null)
                getHedXmlModel(selection.toString())
        }
        menu.add(menuItem)


        menuItem = JMenuItem("Review all tags")
        menuItem.addActionListener {
            showJsonWindow()
        }
        menu.add(menuItem)

        frame.setJMenuBar(menuBar)
    }

    private fun addFieldSelectionPane(mainPane: Container) {
        val fieldSelectionPane = JPanel(FlowLayout())
//        fieldSelectionPane.add(validationStatus)
        val fieldSelectionPaneLabel = JLabel("Tagging field: ")
        fieldSelectionPaneLabel.foreground = Style.BLUE_DARK
        fieldSelectionPaneLabel.font = Font("Sans Serif", Font.BOLD, 14)
        fieldSelectionPane.add(fieldSelectionPaneLabel)
        fieldList.initializeListener()
        fieldSelectionPane.add(fieldList)

        mainPane.add(fieldSelectionPane, BorderLayout.NORTH)
    }

    /**
     * Add field level and tag Input panes
     */
    private fun addCenterPane(mainPane: Container) {
        centerPane = JPanel(GridBagLayout())
        var c = GridBagConstraints()
        c.gridx = 0
        c.gridy = 0
        c.gridwidth = 2
        c.anchor = GridBagConstraints.LINE_START
        val eventPaneLabel = JLabel("Field levels")
        eventPaneLabel.border = EmptyBorder(0,10,0,0)
        eventPaneLabel.foreground = Style.BLUE_DARK
        eventPaneLabel.font = Font("Sans Serif", Font.BOLD, 14)
        centerPane.add(eventPaneLabel, c)

        c = GridBagConstraints()
        c.fill = GridBagConstraints.HORIZONTAL
        c.gridx = 0
        c.gridy = 1
        c.gridwidth = 2
        c.weightx = 0.5
        c.insets = Insets(0,10,0,0)
        val eventCodePane = JScrollPane(eventCodeList)
        eventCodePane.horizontalScrollBarPolicy = JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED
        eventCodePane.verticalScrollBarPolicy = JScrollPane.VERTICAL_SCROLLBAR_ALWAYS
        eventCodePane.preferredSize = Dimension(500,300)
        eventCodePane.background = Style.BLUE_MEDIUM
        centerPane.add(eventCodePane, c)

        c = GridBagConstraints()
        c.gridx = 2
        c.gridy = 0
        c.gridwidth = 1
        c.anchor = GridBagConstraints.LINE_START
        val tagPanelLabel = JLabel("HED tags")
        tagPanelLabel.font = Font("Sans Serif", Font.BOLD, 14)
        tagPanelLabel.border = EmptyBorder(0,10,0,0)
        tagPanelLabel.foreground = Style.BLUE_DARK
        centerPane.add(tagPanelLabel)

        c = GridBagConstraints()
        c.gridx = 5
        c.gridy = 0
        c.gridwidth = 1
        c.anchor = GridBagConstraints.LINE_END
        c.insets = Insets(0,10,0,0)
        val showSchemaBtn = JButton("Show HED schema")
        showSchemaBtn.addActionListener {
            schemaView.show()
        }
        centerPane.add(showSchemaBtn, c)

        c = GridBagConstraints()
        c.gridx = 6
        c.gridy = 0
        c.gridwidth = 1
        c.anchor = GridBagConstraints.LINE_END
//        c.insets = Insets(0,5,0,0)
        val createDefBtn = JButton("Create definition")
        createDefBtn.addActionListener {
            val input = JOptionPane.showInputDialog("Definition name (e.g. 'Show-face')")
            eventCodeList.addDefinition(input)
            SwingUtilities.invokeLater{
                centerPane.repaint()
            }
        }
        centerPane.add(createDefBtn, c)

        c = GridBagConstraints()
        c.gridx = 7
        c.gridy = 0
        c.gridwidth = 1
        c.anchor = GridBagConstraints.LINE_END
//        c.insets = Insets(0,5,0,0)
        val validateBtn = JButton("Validate string")
        validateBtn.addActionListener {
            try {
                val response = validator.validateString(inputPane.getCleanedHEDString())
                if (response.results["msg_category"] == "success")
                    JOptionPane.showMessageDialog(frame,"No issue found")
                else {
                    val jta = JTextArea(response.results["data"].toString().trim('[').trim(']'))
                    val jsp: JScrollPane = object : JScrollPane(jta) {
                        override fun getPreferredSize(): Dimension {
                            return Dimension(500, 320)
                        }
                    }
                    jsp.background = Style.BLUE_MEDIUM
                    JOptionPane.showMessageDialog(frame, jsp, response.results["msg"].toString(), JOptionPane.ERROR_MESSAGE)
                }

            }
            catch (e: Exception) {
                JOptionPane.showMessageDialog(frame,"Error connecting with the online validator.\nPlease try again later or go to https://hedtools.org/hed")
                isValidated = true
            }
        }
        centerPane.add(validateBtn, c)

        inputPane = InputLayeredPane(this)
        inputPane.preferredSize = Dimension(500,300)

        c = GridBagConstraints()
        c.fill = GridBagConstraints.HORIZONTAL
        c.gridx = 2
        c.gridy = 1
        c.gridwidth = 6
        c.weightx = 1.0
        c.insets = Insets(0,0,0,5)
        centerPane.add(inputPane, c)

        mainPane.add(centerPane, BorderLayout.CENTER)
    }

    private fun addBtnPane(mainPane: Container) {
        val btnPane = JPanel()
        val cancelBtn = JButton("Cancel")
        cancelBtn.addActionListener {
            if (!isStandalone) {
                loader!!.notified = true
                loader!!.canceled = true
                frame.dispose()
            }
            else
                exitProcess(0)
        }
        btnPane.add(cancelBtn)

        val validateAllBtn = JButton("Validate all")
        validateAllBtn.addActionListener {
            try {
                val response = if (fieldList.isQuickTagging()) validator.validateString(inputPane.getCleanedHEDString()) else validator.validateSidecar(getFieldMapJson())
                if (response.results["msg_category"] == "success") {
                    isValidated = true
                    JOptionPane.showMessageDialog(frame, "No issue found")
                }
                else {
                    isValidated = false
                    validationStatus.text = "Validation failed"
                    val jta = JTextArea(response.results["data"].toString().trim('[').trim(']'))
                    val jsp: JScrollPane = object : JScrollPane(jta) {
                        override fun getPreferredSize(): Dimension {
                            return Dimension(500, 320)
                        }
                    }
                    jsp.background = Style.BLUE_MEDIUM
                    JOptionPane.showMessageDialog(frame, jsp, response.results["msg"].toString(), JOptionPane.ERROR_MESSAGE)
                }
            }
            catch (e: Exception) {
                JOptionPane.showMessageDialog(frame,"Error connecting to the validator server.\nPlease save your annotation and try again later or go to https://hedtools.ucsd.edu/hed/sidecar")
                isValidated = true
            }
        }
        btnPane.add(validateAllBtn)

        val doneBtn = JButton("Finish")
        doneBtn.addActionListener {
            if (!isValidated) {
                JOptionPane.showMessageDialog(frame,"Unvalidated annotations. Please Validate all annotations before finishing.")
            }
            else {
                showJsonWindow()
                if (!isStandalone) {
                    loader!!.notified = true
                    loader!!.jsonResult = getFieldMapJson()
                    frame.dispose()
                } else
                    exitProcess(0)
//            frame.dispatchEvent(WindowEvent(frame, WindowEvent.WINDOW_CLOSING))
            }
        }
        btnPane.add(doneBtn)
        mainPane.add(btnPane, BorderLayout.SOUTH)
    }

    /**
     * Parse HED schema from hed-standard/hed-specification
     * and build schema model
     * @param version   Version of the schema
     */
    private fun getHedXmlModel(version: String = "HEDLatest") {
        val schemaLink = URL("https://raw.githubusercontent.com/hed-standard/hed-specification/master/hedxml/${version}.xml")
        val xmlData = schemaLink.readText()
        val hedXmlModel: HedXmlModel
        try {
            val context = JAXBContext.newInstance(HedXmlModel::class.java)
            hedXmlModel = context.createUnmarshaller().unmarshal(StringReader(xmlData)) as HedXmlModel
            hedVersion = hedXmlModel.version
        }
        catch (e: Exception) {
            throw RuntimeException("Unable to read XML data: " + e.message)
        }
        unitClasses = hedXmlModel.unitClasses.unitClasses
        unitModifiers = hedXmlModel.unitModifiers.unitModifiers
        val hedRoot = TagModel("", null, null)
        populateTagSets(hedRoot, hedXmlModel.tags, false)
        hedValidator = HedValidator(schema, this)
        schemaView = SchemaView(this, hedRoot)
    }

    /**
     *
     */
    // Add tags recursively
    private fun populateTagSets(parent: TagModel, tagSets: Set<TagXmlModel>, parentExtensionAllowed: Boolean) {
        for (tagXmlModel: TagXmlModel in tagSets) {
            val tagPath = "${parent.fullPath}/${tagXmlModel.name}"
            val tagModel = TagModel(tagPath, parent, tagXmlModel)
            if (parentExtensionAllowed)
                tagModel.setAttribute("extensionAllowed")
            parent.children.add(tagModel)
            val nodes = tagPath.split('/')
            for (i in nodes.size-1 downTo 0) {
                val path = nodes.subList(i, nodes.size).joinToString("/")
                if (path != "#")
                    schema[path] = tagModel
            }
            tags.add(tagPath)
            populateTagSets(tagModel, tagXmlModel.tags, tagModel.hasAttribute("extensionAllowed"))
        }
    }

    /**
     * Export field map (fMap) to json accordingly to HED-BIDS specification
     * https://bids-specification.readthedocs.io/en/stable/99-appendices/03-hed.html#appendix-iii-hierarchical-event-descriptors
     */
    fun exportToJson(fMap: HashMap<String, HashMap<String, String>>): HashMap<String, Any> {
        val jsonFieldMap = HashMap<String, Any>()
        fMap.forEach {
            // value type, ignoring empty fields
            if (fieldList.isValueField.containsKey(it.key) && fieldList.isValueField[it.key]!! && it.value.containsKey("HED") && it.value["HED"]!!.isNotEmpty()) {
                var finalString = it.value["HED"]!!
                finalString = finalString.replace("\n", "")
                finalString = finalString.replace("\t", "")
                jsonFieldMap[it.key] = hashMapOf(Pair("HED", finalString))
            }
            // categorical fields
            else {
                val finalMap = HashMap<String, String>()
                it.value.forEach { map ->
                    // ignore empty codes
                    if (map.value.isNotEmpty()) {
                        // some clean-up
                        var finalString = map.value
                        finalString = finalString.replace("\n", "")
                        finalString = finalString.replace("\t", "")
                        finalMap[map.key] = finalString
                    }
                }
                if (finalMap.isNotEmpty())
                    jsonFieldMap[it.key] = hashMapOf(Pair("HED", finalMap))
            }
        }
        return jsonFieldMap
    }
    fun prettyPrintJson(fieldMap: HashMap<String, Any>): String {
        val gson = GsonBuilder().setPrettyPrinting().create()
        return gson.toJson(fieldMap)
    }

    fun getFieldMapJson(): String {
        return prettyPrintJson(exportToJson(fieldList.fieldMap))
    }

    private fun showJsonWindow() {
        val json = getFieldMapJson()
        val textarea = JTextArea(25,50)
        textarea.text = json
        textarea.lineWrap = true
        textarea.wrapStyleWord = true
        textarea.isEditable = false
        val scroller = JScrollPane(textarea, JScrollPane.VERTICAL_SCROLLBAR_ALWAYS, JScrollPane.HORIZONTAL_SCROLLBAR_NEVER)
        val options1 = arrayOf<Any>("Save to file", "Ok")
        val result = JOptionPane.showOptionDialog(frame, scroller, "BIDS events.json HED string", JOptionPane.YES_NO_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE, null, options1, 1)

        // if save to file selected
        if (result == 0) {
            val fileChooser = JFileChooser()
            fileChooser.selectedFile = File("_events.json")
            val retval = fileChooser.showSaveDialog(frame)
            if (retval == JFileChooser.APPROVE_OPTION) {
                var file = fileChooser.selectedFile ?: return
                if (!file.name.toLowerCase().endsWith(".json")) {
                    file = File(file.parentFile, file.name + ".json")
                }
                try {
                    textarea.write(OutputStreamWriter(FileOutputStream(file),
                            "utf-8"))
//                    Desktop.getDesktop().open(file)
                } catch (e: java.lang.Exception) {
                    e.printStackTrace()
                }
            }
        }
    }
    /**
     * Retrieve event info from .tsv file
     * and populate GUI
     */
    private fun importSpreadsheet(file: File) {
        try {
            val settings = TsvParserSettings()
            settings.format.lineSeparator = "\n".toCharArray()
            val parser = TsvParser(settings)
            // parse file as a collection of rows
            val allRows = parser.parseAll(file)

            // show dialog to verify categorical fields
            var categoricalField = mutableListOf<String>()
            var isCancelled = false

            // create dialog
            val dialog = JDialog(frame, "", true)
            val pane = JPanel(BorderLayout())
            pane.border = EmptyBorder(10, 10, 10, 10)
            val label = JLabel("Indicate specific non-prefixed tag columns (column numbers start with 1):")
            label.border = EmptyBorder(10,0,10,0)
            pane.add(label, BorderLayout.PAGE_START)
            val inputPane = JPanel()
            val layout = GridLayout(0,2)
            inputPane.layout = layout
            inputPane.add(JLabel("Event fields"))
            val fieldCol = JTextField("")
            inputPane.add(fieldCol)
            inputPane.add(JLabel("Field values"))
            val valueCol = JTextField("")
            inputPane.add(valueCol)
            inputPane.add(JLabel("HED annotation"))
            val hedCol = JTextField("")
            inputPane.add(hedCol)
            pane.add(inputPane, BorderLayout.CENTER)
            val btnPane = JPanel()
            val okBtn = JButton("Ok")
            okBtn.addActionListener {
                dialog.dispose()
            }
            val cancelBtn = JButton("Cancel")
            cancelBtn.addActionListener{
                dialog.dispose()
                isCancelled = true
            }
            btnPane.add(okBtn)
            btnPane.add(cancelBtn)
            pane.add(btnPane, BorderLayout.PAGE_END)
            dialog.contentPane = pane
            dialog.pack()
            val dim = Toolkit.getDefaultToolkit().screenSize
            dialog.setLocation(dim.width / 2 - dialog.size.width / 2, dim.height / 2 - dialog.size.height / 2) // put center of screen
            dialog.isVisible = true

            // user entered column indices. Proceed
            if (!isCancelled) {
                val fieldIdx = fieldCol.text.toInt() - 1
                val valueIdx = valueCol.text.toInt() - 1
                val hedIdx = hedCol.text.toInt() - 1
                val fieldMap = HashMap<String,BIDSFieldDict>()
                for ((rowIndex, row) in allRows.withIndex()) {
                    if (rowIndex > 0) {// ignore first row which contains column headers
                        val field = row[fieldIdx]
                        val value = if (row[valueIdx].isNullOrEmpty()) "" else row[valueIdx]
                        val hed =  if (row[hedIdx].isNullOrEmpty()) "" else row[hedIdx].trim('"')

                        if (!fieldMap.containsKey(field))
                            fieldMap[row[fieldIdx]] = BIDSFieldDict()

                        if (value.isEmpty() || value.toLowerCase() == "n/a")
                            fieldMap[field]?.HED = hed
                        else { // categorical values
                            if (fieldMap[field]?.HED.toString().isEmpty()) { // if first time
                                fieldMap[field]?.HED = LinkedTreeMap<String,String>()
                                (fieldMap[field]?.HED as LinkedTreeMap<String,String>)[value] = hed
                            }
                            else
                                (fieldMap[field]?.HED as LinkedTreeMap<String,String>)[value] = hed
                        }
                    }
                }

                // parse successfully. Creating fields
                // reset if not empty
                if (!fieldList.isEmpty()) {
                    JOptionPane.showMessageDialog(frame, "Clearing old fields")
                    fieldList.clear()
                }
                fieldMap.forEach {
                    // assuming that first row contains field names as BIDS TSV
                    // add fields to combo box
                    fieldList.addFieldFromDict(it.key.toLowerCase(), it.value)
                }
                // initialize tagging GUI
                eventCodeList.codeSet = fieldList.fieldAndUniqueCodeMap[fieldList.selectedItem!!]!! // add codes of current field
                eventCodeList.selectedIndex = 0 // select first code in the list
                fieldList.repaint()
            }
        }
        catch (e: Exception) {
            JOptionPane.showMessageDialog(frame, "Error importing BIDS _events.tsv. Make sure that your file is BIDS compliant.", "Import error", JOptionPane.ERROR_MESSAGE)
        }
    }

    /**
     * Retrieve event info from .tsv file
     * and populate GUI
     */
    private fun importBIDSEventTSV(file: File) {
        try {
            val settings = TsvParserSettings()
            settings.format.lineSeparator = "\n".toCharArray()
            val parser = TsvParser(settings)
            // parse file as a collection of rows
            val allRows = parser.parseAll(file)

            // show dialog to verify categorical fields
            var categoricalField = mutableListOf<String>()
            var isCancelled = false
            // create dialog
            val dialog = JDialog(frame, "", true)
            val pane = JPanel(BorderLayout())
            pane.border = EmptyBorder(10, 10, 10, 10)
            val label = JLabel("Select categorical event fields (Hold Ctrl/Cmd for multiple selections)")
            label.border = EmptyBorder(10,0,10,0)
            pane.add(label, BorderLayout.PAGE_START)
            val list = JList<String>(allRows[0])
            val scrollableList = JScrollPane(list)
            scrollableList.horizontalScrollBarPolicy = JScrollPane.HORIZONTAL_SCROLLBAR_AS_NEEDED
            scrollableList.verticalScrollBarPolicy = JScrollPane.VERTICAL_SCROLLBAR_ALWAYS
            pane.add(scrollableList, BorderLayout.CENTER)
            val btnPane = JPanel()
            val okBtn = JButton("Ok")
            okBtn.addActionListener {
                categoricalField = list.selectedValuesList
                if (categoricalField.isEmpty())
                    JOptionPane.showMessageDialog(frame, "No field selected. Treating all fields as numerical fields.")
                dialog.dispose()
            }
            val cancelBtn = JButton("Cancel")
            cancelBtn.addActionListener{
                dialog.dispose()
                isCancelled = true
            }
            btnPane.add(okBtn)
            btnPane.add(cancelBtn)
            pane.add(btnPane, BorderLayout.PAGE_END)
            dialog.contentPane = pane
            dialog.pack()
            val dim = Toolkit.getDefaultToolkit().screenSize
            dialog.setLocation(dim.width / 2 - dialog.size.width / 2, dim.height / 2 - dialog.size.height / 2) // put center of screen
            dialog.isVisible = true

            // user selected categorical fields. Proceed
            if (!isCancelled) {
                val eventFile = Array(allRows[0].size) { Array(allRows.size) { "" } }
                for ((rowIndex, row) in allRows.withIndex()) {
                    for ((colIndex, col) in row.withIndex()) {
                        eventFile[colIndex][rowIndex] = col
                    }
                }

                // parse successfully. Creating fields
                // reset if not empty
                if (!fieldList.isEmpty()) {
                    JOptionPane.showMessageDialog(frame, "Clearing old fields")
                    fieldList.clear()
                }
                eventFile.forEach { column ->
                    // add fields to combo box
                    fieldList.addFieldFromColumn(column, categoricalField.contains(column[0]))
                }
                // initialize tagging GUI
                eventCodeList.codeSet = fieldList.fieldAndUniqueCodeMap[fieldList.selectedItem!!]!! // add codes of current field
                eventCodeList.selectedIndex = 0 // select first code in the list
                fieldList.repaint()
            }
        }
        catch (e: Exception) {
            JOptionPane.showMessageDialog(frame, "Error importing BIDS _events.tsv. Make sure that your file is BIDS compliant.", "Import error", JOptionPane.ERROR_MESSAGE)
        }
    }
    /**
     * Action listener for import events.json menu item
     * Importing events.json and update GUI
     */
    private fun importBIDSEventJson(file: File) {
        try {
            val json: String = file.readText()
            val type: Type = object : TypeToken<HashMap<String?, BIDSFieldDict>?>() {}.type
            val gson = Gson()
            val result: HashMap<String, BIDSFieldDict> = gson.fromJson(json, type)
            // reset if not empty
            if (!fieldList.isEmpty()) {
                JOptionPane.showMessageDialog(frame, "Clearing old fields")
                fieldList.clear()
            }
            result.forEach {
                // assuming that first row contains field names as BIDS TSV
                // add fields to combo box
                fieldList.addFieldFromDict(it.key.toLowerCase(), it.value)
            }
            // initialize/update tagging GUI
            eventCodeList.codeSet = fieldList.fieldAndUniqueCodeMap[fieldList.selectedItem!!]!! // add codes of current field
            eventCodeList.selectedIndex = 0 // select first code in the list
            fieldList.repaint()
        }
        catch (e: Exception) {
            JOptionPane.showMessageDialog(frame, "Error importing BIDS _events.json. Make sure that your file is BIDS compliant", "Import error", JOptionPane.ERROR_MESSAGE)
        }
    }

    private fun importBIDSEventJson(json: String) {
        try {
            val type: Type = object : TypeToken<HashMap<String?, BIDSFieldDict>?>() {}.type
            val gson = Gson()
            val result: HashMap<String, BIDSFieldDict> = gson.fromJson(json, type)
            // reset if not empty
            if (!fieldList.isEmpty()) {
                JOptionPane.showMessageDialog(frame, "Clearing old fields")
                fieldList.clear()
            }
            result.forEach {
                // assuming that first row contains field names as BIDS TSV
                // add fields to combo box
                fieldList.addFieldFromDict(it.key.toLowerCase(), it.value)
            }
            // initialize/update tagging GUI
            eventCodeList.codeSet = fieldList.fieldAndUniqueCodeMap[fieldList.selectedItem!!]!! // add codes of current field
            eventCodeList.selectedIndex = 0 // select first code in the list
            fieldList.repaint()
        }
        catch (e: Exception) {
            JOptionPane.showMessageDialog(frame, "Error importing", "Import error", JOptionPane.ERROR_MESSAGE)
        }
    }

    /** Functions for fieldMap handling **/
    fun getHedString(field: String, code: String): String {
        return fieldList.getHedString(field, code)
    }
    /*****/

    /** Delegator methods for inputPane **/
    fun hideSearchResultPane() {
        inputPane.hideSearchResultPane()
    }

    fun showSearchResultPane(x: Int, y: Int) {
        inputPane.showSearchResultPane(x,y)
    }

    fun isSearchResultEmpty(): Boolean {
        return inputPane.isSearchResultEmpty()
    }

    fun addTagsToSearchResult(matchedTags: List<String>) {
        inputPane.addTagsToSearchResult(matchedTags)

    }

    fun isSearchResultVisible(): Boolean {
        return inputPane.isSearchResultVisible()
    }

    fun showSearchResultWhenKeyPressed() {
        inputPane.showSearchResultWhenDownKeyPressed()
    }

    fun clearSearchResult() {
        inputPane.clearSearchResult()
    }

    /**
     * Show error message dialog
     */
    fun showErrorMessage(message: String) {
        JOptionPane.showMessageDialog(frame, message, "Error", JOptionPane.ERROR_MESSAGE)
    }

    /**
     * For deserialization of json
     */
    class BIDSFieldDict{
        var LongName:String = ""
        var Description:String = ""
        var Levels:HashMap<String,String> = HashMap()
        var Units:String = ""
        var HED:Any = ""
    }
    class LinkObject {
        var self: String = ""
        var git: String = ""
        var html: String = ""
    }
    class SchemaListObject {
        var name:String = ""
        var path:String = ""
        var sha:String = ""
        var size:Int = 0
        var url:String = ""
        var html_url = ""
        var git_url = ""
        var download_url = ""
        var type = ""
        var _links: CTagger.LinkObject? = null
    }

}

