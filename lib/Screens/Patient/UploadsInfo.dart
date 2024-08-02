import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shimmer/shimmer.dart';

class UploadsInfo extends StatefulWidget {
  final bool isImage;
  final String patientEmail;

  const UploadsInfo({
    super.key,
    required this.isImage,
    required this.patientEmail,
  });

  @override
  _UploadsInfoState createState() => _UploadsInfoState();
}

class _UploadsInfoState extends State<UploadsInfo> {
  late Future<List<DocumentSnapshot>> _uploadsFuture;

  @override
  void initState() {
    super.initState();
    _uploadsFuture = fetchUploads();
  }

  Future<List<DocumentSnapshot>> fetchUploads() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('uploads')
          .where('isImage', isEqualTo: widget.isImage)
          .where('patientEmail', isEqualTo: widget.patientEmail)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching uploads: $e');
      return [];
    }
  }

  Future<void> deleteUpload(
      String documentId, String fileURL, bool isImage) async {
    try {
      await FirebaseFirestore.instance
          .collection('uploads')
          .doc(documentId)
          .delete();
      await FirebaseStorage.instance.refFromURL(fileURL).delete();
      setState(() {
        _uploadsFuture = fetchUploads();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload deleted successfully!')),
      );
    } catch (e) {
      print('Error deleting upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete upload')),
      );
    }
  }

  // void _showDeleteConfirmationDialog(
  //     String documentId, String fileURL, bool isImage) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Delete Confirmation'),
  //         content: const Text('Are you sure you want to delete this record?'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Yes'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               deleteUpload(documentId, fileURL, isImage);
  //             },
  //           ),
  //           TextButton(
  //             child: const Text('No'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(414, 896));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Uploads Info',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _uploadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<DocumentSnapshot>? uploads = snapshot.data;
            if (uploads == null || uploads.isEmpty) {
              return const Center(child: Text('No uploads found'));
            }
            return ListView.builder(
              itemCount: uploads.length,
              itemBuilder: (context, index) {
                var upload = uploads[index];
                bool isImage = upload['isImage'];
                String fileURL = upload['fileURL'];
                String description = upload['description'];
                Timestamp timestamp = upload['timestamp'];
                String documentId = upload.id;

                return UploadCard(
                  isImage: isImage,
                  fileURL: fileURL,
                  description: description,
                  timestamp: timestamp,
                  documentId: documentId,
                  // onDelete: () {
                  //   _showDeleteConfirmationDialog(documentId, fileURL, isImage);
                  // },
                );
              },
            );
          }
        },
      ),
    );
  }
}

class UploadCard extends StatefulWidget {
  final bool isImage;
  final String fileURL;
  final String description;
  final Timestamp timestamp;
  final String documentId;
  // final VoidCallback onDelete;

  const UploadCard({
    super.key,
    required this.isImage,
    required this.fileURL,
    required this.description,
    required this.timestamp,
    required this.documentId,
    // required this.onDelete,
  });

  @override
  _UploadCardState createState() => _UploadCardState();
}

class _UploadCardState extends State<UploadCard> {
  VideoPlayerController? _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isImage) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.fileURL))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    DateFormat dateFormat = DateFormat('d MMM yyyy, hh:mm a');
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                if (widget.isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.sp),
                    child: Image.network(
                      widget.fileURL,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[300],
                            ),
                          );
                        }
                      },
                    ),
                  )
                else if (_isVideoInitialized)
                  AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller!.value.isPlaying
                              ? _controller!.pause()
                              : _controller!.play();
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.sp),
                            child: VideoPlayer(_controller!),
                          ),
                          if (!_controller!.value.isPlaying)
                            const Icon(
                              Icons.play_arrow,
                              size: 80,
                              color: Colors.white,
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10.sp),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              widget.description,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5.h),
            Text(
              dateFormat.format(widget.timestamp.toDate()),
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 10.h),
            // Align(
            //   alignment: Alignment.bottomRight,
            //   child: IconButton(
            //     icon: const Icon(Icons.delete, color: Colors.red),
            //     onPressed: widget.onDelete,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
