package com.example.flutterwallcrop

import android.graphics.*
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.OutputStream
import java.util.*

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.fluttercropphoto/image_crop"
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            val path = call.argument<String>("path")
            val scale = call.argument<Double>("scale")!!
            val left = call.argument<Double>("left")!!
            val top = call.argument<Double>("top")!!
            val right = call.argument<Double>("right")!!
            val bottom = call.argument<Double>("bottom")!!
            val area = RectF(left.toFloat(), top.toFloat(), right.toFloat(), bottom.toFloat())
            cropImage(path!!, area, scale.toFloat(), result)
        }
    }

    @Throws(IOException::class)
    private fun createTemporaryImageFile(): File {
        val directory = activity.cacheDir
        val name = "image_crop_" + UUID.randomUUID().toString()
        return File.createTempFile(name, ".jpg", directory)
    }

    @Throws(IOException::class)
    private fun compressBitmap(bitmap: Bitmap, file: File) {
        val outputStream: OutputStream = FileOutputStream(file)
        try {
            val compressed = bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream)
            if (!compressed) {
                throw IOException("Failed to compress bitmap into JPEG")
            }
        } finally {
            try {
                outputStream.close()
            } catch (ignore: IOException) {
            }
        }
    }

    private fun cropImage(path : String, area : RectF, scale : Float, result : MethodChannel.Result){
        val srcFile = File(path)
        if(!srcFile.exists()){
            result.error("INVALID", "Image source cannot be opened", null)
            return
        }
        val srcBitmap = BitmapFactory.decodeFile(path)
        compressBitmap(srcBitmap, srcFile)
        if(srcBitmap == null){
            result.error("INVALID", "Image source cannot be decoded", null)
            return
        }
        //
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        BitmapFactory.decodeFile(path, options)
        val width : Int = (options.outWidth * area.width() * scale).toInt()
        val height : Int = (options.outHeight * area.height() * scale).toInt()
        //
        val dstBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(dstBitmap)
        val paint = Paint()
        paint.isAntiAlias = true
        paint.isFilterBitmap = true
        paint.isDither = true
        val left = srcBitmap.width * area.left
        val right = srcBitmap.width * area.right
        val top = srcBitmap.height * area.top
        val bottom = srcBitmap.height * area.bottom
        val srcReact = Rect(left.toInt(), top.toInt(), right.toInt(), bottom.toInt())

        val dstRect = Rect(0,0, width, height)
        canvas.drawBitmap(srcBitmap, srcReact, dstRect, paint)
        try {
            val dstFile: File = createTemporaryImageFile()
            compressBitmap(dstBitmap, dstFile)
            result.success(dstFile.absolutePath)
        }catch (e : IOException){
            result.error("INVALID", "Image could not be saved", e)
        }finally {
            canvas.setBitmap(null)
            dstBitmap.recycle()
            srcBitmap.recycle()
        }
    }
}
