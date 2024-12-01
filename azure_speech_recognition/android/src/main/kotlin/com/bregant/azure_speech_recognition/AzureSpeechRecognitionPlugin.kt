package com.bregant.azure_speech_recognition

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import com.microsoft.cognitiveservices.speech.audio.AudioConfig
import com.microsoft.cognitiveservices.speech.intent.LanguageUnderstandingModel
import com.microsoft.cognitiveservices.speech.intent.IntentRecognitionResult
import com.microsoft.cognitiveservices.speech.intent.IntentRecognizer
import com.bregant.azure_speech_recognition.MicrophoneStream
import com.microsoft.cognitiveservices.speech.transcription.*

import android.app.Activity

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.Callable
import android.os.Handler
import android.os.Looper
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
//import androidx.core.app.ActivityCompat;
import java.net.URI
import android.util.Log
import android.text.TextUtils
import com.microsoft.cognitiveservices.speech.*

import java.util.concurrent.Semaphore


/** AzureSpeechRecognitionPlugin */
class AzureSpeechRecognitionPlugin : FlutterPlugin, Activity(), MethodCallHandler {
    private lateinit var azureChannel: MethodChannel
    private lateinit var handler: Handler
    var continuousListeningStarted: Boolean = false
    lateinit var reco: SpeechRecognizer
    lateinit var config: SpeechConfig
    lateinit var stopRecognitionSemaphore: Semaphore
    lateinit var transcribe: ConversationTranscriber
    lateinit var task_global: Future<SpeechRecognitionResult>

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        azureChannel = MethodChannel(
            flutterPluginBinding.getFlutterEngine().getDartExecutor(), "azure_speech_recognition"
        )
        azureChannel.setMethodCallHandler(this)

    }

    init {
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "azure_speech_recognition")

            this.azureChannel = MethodChannel(registrar.messenger(), "azure_speech_recognition")
            this.azureChannel.setMethodCallHandler(this)
        }

        handler = Handler(Looper.getMainLooper())
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val speechSubscriptionKey: String = call.argument("subscriptionKey") ?: ""
        val serviceRegion: String = call.argument("region") ?: ""
        val lang: String = call.argument("language") ?: ""
        val diarization: String = call.argument("diarization") ?: ""
        val timeoutMs: String = call.argument("timeout") ?: ""
        val referenceText: String = call.argument("referenceText") ?: ""
        val phonemeAlphabet: String = call.argument("phonemeAlphabet") ?: "IPA"
        val granularityString: String = call.argument("granularity") ?: "phoneme"
        val enableMiscue: Boolean = call.argument("enableMiscue") ?: false
        val nBestPhonemeCount: Int? = call.argument("nBestPhonemeCount") ?: null
        val granularity: PronunciationAssessmentGranularity
        when (granularityString) {
            "text" -> {
                granularity = PronunciationAssessmentGranularity.FullText
            }

            "word" -> {
                granularity = PronunciationAssessmentGranularity.Word
            }

            else -> {
                granularity = PronunciationAssessmentGranularity.Phoneme
            }
        }
        when (call.method) {
            "simpleVoice" -> {
                simpleSpeechRecognition(speechSubscriptionKey, serviceRegion, lang, timeoutMs)
                result.success(true)
            }

            "simpleVoiceWithAssessment" -> {
                simpleSpeechRecognitionWithAssessment(
                    referenceText,
                    phonemeAlphabet,
                    granularity,
                    enableMiscue,
                    speechSubscriptionKey,
                    serviceRegion,
                    lang,
                    timeoutMs,
                    nBestPhonemeCount,
                )
                result.success(true)
            }

            "isContinuousRecognitionOn" -> {
                result.success(continuousListeningStarted)
            }

            "continuousStream" -> {
                micStreamContinuously(speechSubscriptionKey, serviceRegion, lang, diarization)
                result.success(true)
            }

            "continuousStreamWithAssessment" -> {
                micStreamContinuouslyWithAssessment(
                    referenceText,
                    phonemeAlphabet,
                    granularity,
                    enableMiscue,
                    speechSubscriptionKey,
                    serviceRegion,
                    lang,
                    nBestPhonemeCount,
                )
                result.success(true)
            }

            "stopContinuousStream" -> {
                result.success(true)
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        azureChannel.setMethodCallHandler(null)
    }

    private fun simpleSpeechRecognition(
        speechSubscriptionKey: String, serviceRegion: String, lang: String, timeoutMs: String
    ) {
        val logTag: String = "simpleVoice"
        try {

            val audioInput: AudioConfig = AudioConfig.fromDefaultMicrophoneInput()

            val config: SpeechConfig =
                SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion)

            config.speechRecognitionLanguage = lang
            config.setProperty(PropertyId.Speech_SegmentationSilenceTimeoutMs, timeoutMs)

            val reco: SpeechRecognizer = SpeechRecognizer(config, audioInput)

            val task: Future<SpeechRecognitionResult> = reco.recognizeOnceAsync()

            task_global = task

            invokeMethod("speech.onRecognitionStarted", null)

            reco.recognizing.addEventListener { _, speechRecognitionResultEventArgs ->
                val s = speechRecognitionResultEventArgs.result.text
                Log.i(logTag, "Intermediate result received: " + s)
                if (task_global === task) {
                    invokeMethod("speech.onSpeech", s)
                }
            }

            setOnTaskCompletedListener(task) { result ->
                val s = result.text
                Log.i(logTag, "Recognizer returned: " + s)
                if (task_global === task) {
                    if (result.reason == ResultReason.RecognizedSpeech) {
                        invokeMethod("speech.onFinalResponse", mapOf("argument1" to s, "argument2" to ""))

                    } else {
                        invokeMethod("speech.onFinalResponse", mapOf("argument1" to "", "argument2" to ""))

                    }
                }
                reco.close()
            }

        } catch (exec: Exception) {
            Log.i(logTag, "ERROR")
            assert(false)
            invokeMethod("speech.onException", "Exception: " + exec.message)

        }
    }

    private fun simpleSpeechRecognitionWithAssessment(
        referenceText: String,
        phonemeAlphabet: String,
        granularity: PronunciationAssessmentGranularity,
        enableMiscue: Boolean,
        speechSubscriptionKey: String,
        serviceRegion: String,
        lang: String,
        timeoutMs: String,
        nBestPhonemeCount: Int?,
    ) {
        val logTag: String = "simpleVoiceWithAssessment"


        try {

            var audioInput: AudioConfig = AudioConfig.fromDefaultMicrophoneInput()

            var config: SpeechConfig =
                SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion)

            config.speechRecognitionLanguage = lang
            config.setProperty(PropertyId.Speech_SegmentationSilenceTimeoutMs, timeoutMs)

            var pronunciationAssessmentConfig: PronunciationAssessmentConfig =
                PronunciationAssessmentConfig(
                    referenceText,
                    PronunciationAssessmentGradingSystem.HundredMark,
                    granularity,
                    enableMiscue
                )
            pronunciationAssessmentConfig.setPhonemeAlphabet(phonemeAlphabet)

            if (nBestPhonemeCount != null) {
                pronunciationAssessmentConfig.setNBestPhonemeCount(nBestPhonemeCount)
            }

            Log.i(logTag, pronunciationAssessmentConfig.toJson())

            val reco: SpeechRecognizer = SpeechRecognizer(config, audioInput)

            pronunciationAssessmentConfig.applyTo(reco)

            val task: Future<SpeechRecognitionResult> = reco.recognizeOnceAsync()

            task_global = task

            invokeMethod("speech.onRecognitionStarted", null)

            reco.recognizing.addEventListener { _, speechRecognitionResultEventArgs ->
                val s = speechRecognitionResultEventArgs.result.text
                Log.i(logTag, "Intermediate result received: " + s)
                if (task_global === task) {
                    invokeMethod("speech.onSpeech", s)
                }
            }

            setOnTaskCompletedListener(task) { result ->
                val s = result.text
                val pronunciationAssessmentResultJson =
                    result.properties.getProperty(PropertyId.SpeechServiceResponse_JsonResult)
                Log.i(logTag, "Final result: $s\nReason: ${result.reason}")
                Log.i(
                    logTag, "pronunciationAssessmentResultJson: $pronunciationAssessmentResultJson"
                )
                if (task_global === task) {
                    if (result.reason == ResultReason.RecognizedSpeech) {
                        invokeMethod("speech.onFinalResponse", mapOf("argument1" to s, "argument2" to ""))
                        invokeMethod("speech.onAssessmentResult", pronunciationAssessmentResultJson)
                    } else {
                        invokeMethod("speech.onFinalResponse", mapOf("argument1" to "", "argument2" to ""))

                        invokeMethod("speech.onAssessmentResult", "")
                    }
                }
                reco.close()
            }

        } catch (exec: Exception) {
            Log.i(logTag, "ERROR")
            assert(false)
            invokeMethod("speech.onException", "Exception: " + exec.message)

        }
    }

    private fun micStreamContinuously(
        speechSubscriptionKey: String, serviceRegion: String, lang: String, diarization: String
    ) {
        val logTag: String = "micStreamContinuous"
        Log.i(logTag, "Continuous recognition here: $continuousListeningStarted")

        if(diarization != "yes"){
            if (continuousListeningStarted) {
                val _task1 = reco.stopContinuousRecognitionAsync()

                setOnTaskCompletedListener(_task1) { result ->
                    Log.i(logTag, "Continuous recognition stopped.")
                    continuousListeningStarted = false
                    invokeMethod("speech.onRecognitionStopped", null)
                    reco.close()
                }
                return
            }

            try {
                val audioConfig: AudioConfig = AudioConfig.fromDefaultMicrophoneInput()

                val config: SpeechConfig =
                    SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion)

                config.speechRecognitionLanguage = lang

                reco = SpeechRecognizer(config, audioConfig)

                reco.recognizing.addEventListener { _, speechRecognitionResultEventArgs ->
                    val s = speechRecognitionResultEventArgs.result.text
                    Log.i(logTag, "Intermediate result received: $s")
                    invokeMethod("speech.onSpeech", s)
                }

                reco.recognized.addEventListener { _, speechRecognitionResultEventArgs ->
                    val s = speechRecognitionResultEventArgs.result.text
                    Log.i(logTag, "Final result received: $s")
                    invokeMethod("speech.onFinalResponse", mapOf("argument1" to s, "argument2" to ""))
                }

                val _task2 = reco.startContinuousRecognitionAsync()

                setOnTaskCompletedListener(_task2) {
                    continuousListeningStarted = true
                    invokeMethod("speech.onRecognitionStarted", null)
                }
            } catch (exec: Exception) {
                assert(false)
                invokeMethod("speech.onException", "Exception: " + exec.message)
            }

        }else {

            if (continuousListeningStarted) {
                val _task1 = transcribe.stopTranscribingAsync()
                setOnTaskCompletedListener(_task1) { result ->
                    Log.i(logTag, "Continuous recognition stopped.")
                    continuousListeningStarted = false
                    invokeMethod("speech.onRecognitionStopped", null)
                    transcribe.close()
                }
                return
            }

            try {
                val audioConfig: AudioConfig = AudioConfig.fromDefaultMicrophoneInput()

                val config: SpeechConfig =
                    SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion)

                config.setSpeechRecognitionLanguage(lang);
                stopRecognitionSemaphore = Semaphore(0)

                transcribe = ConversationTranscriber(config, audioConfig)

                // Subscribes to events.
                transcribe.transcribing.addEventListener { s: Any?, e: ConversationTranscriptionEventArgs ->
                    val s = e.result.text
                    invokeMethod("speech.onSpeech", s)
                }
                transcribe.transcribed.addEventListener { s: Any?, e: ConversationTranscriptionEventArgs ->
                    if (e.result.reason == ResultReason.RecognizedSpeech) {
                        val s = e.result.text
                        val id = e.result.speakerId
                        invokeMethod(
                            "speech.onFinalResponse",
                            mapOf("argument1" to s, "argument2" to id)
                        )
                    } else if (e.result.reason == ResultReason.NoMatch) {
                        println("NOMATCH: Speech could not be transcribed.")
                    }
                }

                transcribe.canceled.addEventListener { s: Any?, e: ConversationTranscriptionCanceledEventArgs ->
                    println("CANCELED: Reason=" + e.reason)
                    if (e.reason == CancellationReason.Error) {
                        println("CANCELED: ErrorCode=" + e.errorCode)
                        println("CANCELED: ErrorDetails=" + e.errorDetails)
                        println("CANCELED: Did you update the subscription info?")
                    }
                    stopRecognitionSemaphore.release()
                }
                transcribe.sessionStarted.addEventListener { s: Any?, e: SessionEventArgs? ->
                    println(
                        "\n    Session started event."
                    )
                }
                transcribe.sessionStopped.addEventListener { s: Any?, e: SessionEventArgs? ->
                    println(
                        "\n    Session stopped event."
                    )
                    stopRecognitionSemaphore.acquire()
                }
                transcribe.startTranscribingAsync().get()
                continuousListeningStarted = true

            } catch (exec: Exception) {
                assert(false)
                invokeMethod("speech.onException", "Exception: " + exec.message)
            }
        }
    }


    private fun stopContinuousMicStream() {
        val logTag: String = "stopContinuousMicStream"
        Log.i(logTag, "Continuous recognition started: $continuousListeningStarted")
    }


    private fun micStreamContinuouslyWithAssessment(
        referenceText: String,
        phonemeAlphabet: String,
        granularity: PronunciationAssessmentGranularity,
        enableMiscue: Boolean,
        speechSubscriptionKey: String,
        serviceRegion: String,
        lang: String,
        nBestPhonemeCount: Int?,
    ) {
        val logTag: String = "micStreamContinuousWithAssessment"

        Log.i(logTag, "Continuous recognition started: $continuousListeningStarted")

        if (continuousListeningStarted) {
            val endingTask = reco.stopContinuousRecognitionAsync()

            setOnTaskCompletedListener(endingTask) { result ->
                Log.i(logTag, "Continuous recognition stopped.")
                continuousListeningStarted = false
                invokeMethod("speech.onRecognitionStopped", null)
                reco.close()
            }
            return
        }

        try {
            val audioConfig: AudioConfig = AudioConfig.fromDefaultMicrophoneInput()

            val config: SpeechConfig =
                SpeechConfig.fromSubscription(speechSubscriptionKey, serviceRegion)

            config.speechRecognitionLanguage = lang

            var pronunciationAssessmentConfig: PronunciationAssessmentConfig =
                PronunciationAssessmentConfig(
                    referenceText,
                    PronunciationAssessmentGradingSystem.HundredMark,
                    granularity,
                    enableMiscue
                )
            pronunciationAssessmentConfig.setPhonemeAlphabet(phonemeAlphabet)

            if (nBestPhonemeCount != null) {
                pronunciationAssessmentConfig.setNBestPhonemeCount(nBestPhonemeCount)
            }

            Log.i(logTag, pronunciationAssessmentConfig.toJson())

            reco = SpeechRecognizer(config, audioConfig)

            pronunciationAssessmentConfig.applyTo(reco)

            reco.recognizing.addEventListener { _, speechRecognitionResultEventArgs ->
                val s = speechRecognitionResultEventArgs.result.text
                Log.i(logTag, "Intermediate result received: $s")
                Log.i(logTag, "Just val: $s")
                invokeMethod("speech.onSpeech", s)
            }

            reco.recognized.addEventListener { _, speechRecognitionResultEventArgs ->
                val result = speechRecognitionResultEventArgs.result;
                val s = result.text
                val pronunciationAssessmentResultJson =
                    result.properties.getProperty(PropertyId.SpeechServiceResponse_JsonResult)
                Log.i(logTag, "Final result received: $s")
                Log.i(
                    logTag, "pronunciationAssessmentResultJson: $pronunciationAssessmentResultJson"
                )
                invokeMethod("speech.onFinalResponse", mapOf("argument1" to s, "argument2" to ""))

                invokeMethod("speech.onAssessmentResult", pronunciationAssessmentResultJson)
            }

            val startingTask = reco.startContinuousRecognitionAsync()

            setOnTaskCompletedListener(startingTask) {
                continuousListeningStarted = true
                invokeMethod("speech.onRecognitionStarted", null)
            }
        } catch (exec: Exception) {
            assert(false)
            invokeMethod("speech.onException", "Exception: " + exec.message)
        }
    }

    private val s_executorService: ExecutorService = Executors.newCachedThreadPool()


    private fun <T> setOnTaskCompletedListener(task: Future<T>, listener: (T) -> Unit) {
        s_executorService.submit {
            val result = task.get()
            listener(result)
        }
    }

    private fun invokeMethod(method: String, arguments: Any?) {
        handler.post {
            azureChannel.invokeMethod(method, arguments)
        }
    }
}
