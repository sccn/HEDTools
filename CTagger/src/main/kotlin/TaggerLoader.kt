import java.awt.Color
import javax.swing.SwingUtilities
import javax.swing.UIManager




fun main() {
<<<<<<< HEAD
    TaggerLoader("""{
    "type": {
        "Description": "Description for type",
        "HED": {
	        "rt": "(Label/type, Label/rt)",
	        "square": "(Label/type, Label/square)"
	    },
        "Levels": {
	        "rt": "Here describe column value rt of column type",
	        "square": "Here describe column value square of column type"
    	}
    },
    "position": {
        "Description": "Description for position",
        "HED": {
	        "1": "(Label/position, Label/1)",
	        "2": "(Label/position, Label/2)"
    	},
        "Levels": {
	        "1": "Here describe column value 1 of column position",
	        "2": "Here describe column value 2 of column position"
	    }
    },
    "latency": {
        "Description": "Description for latency",
        "HED": "(Label/latency, Label/#)"
    }
}""".trimIndent())
=======
    TaggerLoader("{'duration':{'HED':'Data-feature,Duration/#'},'init_index':{'HED':''},'init_time':{'HED':''},'inset':{'HED':''},'load':{'HED':''},'pres_trial':{'HED':''},'reqdur':{'HED':''},'reqtime':{'HED':''},'rt':{'HED':''},'stimulus':{'HED':{'Picture':'Image,Sensory-event','Response':'Agent-action,Participant-response','Sound':''}},'ttime':{'HED':''},'type':{'HED':{'x1':'','x255':'','B':'','C':'','D':'','F':'','G':'','H':'','J':'','K':'','L':'','M':'','N':'','P':'','Q':'','R':'','S':'','T':'','V':'','W':'','WM':'','X':'','Y':'','Z':'','correct':'','gB':'','gC':'','gD':'','gF':'','gG':'','gH':'','gJ':'','gK':'','gL':'','gM':'','gN':'','gP':'','gQ':'','gR':'','gS':'','gT':'','gV':'','gW':'','gX':'','gY':'','gZ':'','nonWM':'','rB':'','rC':'','rD':'','rF':'','rG':'','rH':'','rJ':'','rK':'','rL':'','rM':'','rN':'','rP':'','rQ':'','rR':'','rS':'','rT':'','rV':'','rW':'','rX':'','rY':'','rZ':'','wrong':''}},'uncertainty1':{'HED':''},'uncertainty2':{'HED':''}}")//,"init_index":{"HED":""},"init_time":{"HED":""},"inset":{"HED":""},"load":{"HED":""},"pres_trial":{"HED":""},"reqdur":{"HED":""},"reqtime":{"HED":""},"rt":{"HED":""},"stimulus":{"HED":{"Picture":"","Response":"","Sound":""}},"ttime":{"HED":""},"type":{"HED":{"x1":"","x255":"","B":"","C":"","D":"","F":"","G":"","H":"","J":"","K":"","L":"","M":"","N":"","P":"","Q":"","R":"","S":"","T":"","V":"","W":"","WM":"","X":"","Y":"","Z":"","correct":"","gB":"","gC":"","gD":"","gF":"","gG":"","gH":"","gJ":"","gK":"","gL":"","gM":"","gN":"","gP":"","gQ":"","gR":"","gS":"","gT":"","gV":"","gW":"","gX":"","gY":"","gZ":"","nonWM":"","rB":"","rC":"","rD":"","rF":"","rG":"","rH":"","rJ":"","rK":"","rL":"","rM":"","rN":"","rP":"","rQ":"","rR":"","rS":"","rT":"","rV":"","rW":"","rX":"","rY":"","rZ":"","wrong":""}},"uncertainty1":{"HED":""},"uncertainty2":{"HED":""}}')
>>>>>>> main
}

/**
 * To load CTagger in EEGLAB
 */
class TaggerLoader(var jsonString:String) {
    val defaultBackgroundColor = UIManager.getColor("Panel.background")
    var notified: Boolean = false
    var canceled: Boolean = false
    var jsonResult: String = ""
    init {
        SwingUtilities.invokeLater {
            val tagger = CTagger(isStandalone = false, isJson = true, isTSV = false, filename = "", jsonString = jsonString, isScratch = true)
            tagger.loader = this
        }
    }
    public fun isNotified(): Boolean {
        UIManager.put("Panel.background", defaultBackgroundColor)
        UIManager.put("OptionPane.background", defaultBackgroundColor)
        return notified
    }
    public fun getHEDJson(): String {
        return jsonResult
    }
    public fun isCanceled(): Boolean {
        return canceled
    }
}