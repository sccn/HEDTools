import com.github.kittinunf.fuel.Fuel
import com.github.kittinunf.fuel.core.extensions.jsonBody
import com.github.kittinunf.fuel.httpGet
import com.github.kittinunf.result.Result
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import java.lang.Exception

data class HEDWebsericeResponse(val service: String, val command: String, val command_target: String, val results: HashMap<String,Any>, val error_type: String, val error_msg: String)
class HEDWebService {
        fun validateString(hedString: String, schemaVersion: String = "8.3.0"): HEDWebsericeResponse {
            val server = "https://hedtools.org/hed/"
            val (csrfToken, cookies) = getSessionInfo(server + "services")
            val gson = GsonBuilder().setPrettyPrinting().create()
            val requestBody = gson.toJson(
                mapOf(
                    "service" to "strings_validate",
                    "schema_version" to schemaVersion,
                    "string_list" to listOf(hedString),
                    "check_for_warnings" to "on"
                )
            )

            val (request, response, result) = Fuel.post(server + "services_submit")
                .header(Pair("X-CSRFToken", csrfToken), Pair("Accept", "application/json"), Pair("Cookie", cookies))
                .jsonBody(requestBody)
                .responseString()
            when (result) {
                is Result.Failure -> {
                    // print failure message
                    throw Exception("Error connecting to the online validator")
                }
                is Result.Success -> {
                    val data = result.get()
                    val gson = Gson()
                    val hedResponse = gson.fromJson(data, HEDWebsericeResponse::class.java)
                    return hedResponse
                }
            }
        }

<<<<<<< HEAD
        fun validateSidecar(hedSidecarString: String, schema: String = "8.3.0"): HEDWebsericeResponse {
            val server = "https://hedtools.org/hed/"
=======
        fun validateSidecar(hedSidecarString: String, schema: String = "8.0.0"): HEDWebsericeResponse {
            val server = "https://hedtools.ucsd.edu/hed/"
>>>>>>> main
            val (csrfToken, cookies) = getSessionInfo(server + "services")
            val gson = GsonBuilder().setPrettyPrinting().create()
            val requestBody = gson.toJson(
                mapOf(
                    "service" to "sidecar_validate",
                    "schema_version" to schema,
<<<<<<< HEAD
                    "sidecar_string" to hedSidecarString,
                    "check_for_warnings" to "on"
=======
                    "json_string" to hedSidecarString,
                    "check_warnings_validate" to "on"
>>>>>>> main
                )
            )

            val (request, response, result) = Fuel.post(server + "services_submit")
                .header(Pair("X-CSRFToken", csrfToken), Pair("Accept", "application/json"), Pair("Cookie", cookies))
                .jsonBody(requestBody)
                .responseString()
            when (result) {
                is Result.Failure -> {
//                    val ex = result.error
                    throw Exception("Error connecting to the online validator")
                }
                is Result.Success -> {
                    val data = result.get()
                    val gson = Gson()
                    val hedResponse = gson.fromJson(data, HEDWebsericeResponse::class.java)
                    return hedResponse
                }
            }
        }
        fun getSessionInfo(csrfURL: String): Pair<String, String> {
            val (request, response, result) = csrfURL
                .httpGet()
                .responseString()

            when (result) {
                is Result.Failure -> {
//                    val ex = result.error
                    throw Exception("Error connecting to the online validator")
                }
                is Result.Success -> {
                    val data = result.get()
                    val doc: Document = Jsoup.parse(data)
                    val input = doc.getElementsByTag("input")
                    val csrfToken = input.attr("value")
                    val cookies = response.headers["Set-Cookie"].toString().trim('[').trim(']')
                    return Pair(csrfToken, cookies)
                }
            }
        }
}
