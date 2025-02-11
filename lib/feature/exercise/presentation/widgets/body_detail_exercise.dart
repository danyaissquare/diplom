import 'dart:collection';
import 'dart:io';

import 'package:date_time_picker/date_time_picker.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/alert_dialog1.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/alert_dialog2.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/open_image.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/parse_time.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/spinkit.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/type_file.dart';
import 'package:thuc_tap_tot_nghiep/core/config/injection_container.dart';
import 'package:thuc_tap_tot_nghiep/feature/answer/presentation/manager/get_info_answer/get_info_answer_bloc.dart';
import 'package:thuc_tap_tot_nghiep/feature/answer/presentation/pages/info_answer_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/answer/presentation/widgets/grading_summary.dart';
import 'package:thuc_tap_tot_nghiep/feature/answer/presentation/widgets/submit_status.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/data/data_source/delete_exercise.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/data/data_source/edit_exercise.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/data/models/get_exercise_by_course_res.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/data/models/get_info_exercise_res.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/manager/get_info_exercise/get_info_exercise_bloc.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/manager/get_info_exercise/get_info_exercise_event.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/manager/get_info_exercise/get_info_exercise_state.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/create_exercise_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/detail_course_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/detail_exercise_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/execise_page.dart';
import 'package:thuc_tap_tot_nghiep/core/config/components/thumbnail.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/grade_exercise_teacher_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/pages/submit_exercise_page.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/widgets/accpect_button.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/widgets/list_file.dart';
import 'package:thuc_tap_tot_nghiep/feature/exercise/presentation/widgets/pick_multi_file.dart';
import 'package:thuc_tap_tot_nghiep/main.dart';

var dio = Dio();

class BodyDetailExercise extends StatefulWidget {
  final int? idExercise;
  final String? descriptionExercise;
  final String? allowSubmission;
  final String? submissionDeadline;
  final String? nameExercise;

  const BodyDetailExercise(
      {Key? key,
      this.idExercise,
      this.nameExercise,
      this.descriptionExercise,
      this.submissionDeadline,
      this.allowSubmission})
      : super(key: key);

  @override
  _BodyDetailExerciseState createState() => _BodyDetailExerciseState();
}

class _BodyDetailExerciseState extends State<BodyDetailExercise> {
  List<PlatformFile>? listFile;
  final Dio dio = Dio();

  TextEditingController? nameExeController;
  String? nameExe;

  bool? isEdit;
  TextEditingController? textEditingController;
  String? textDescription;
  List<Files>? tempList;
  FilePickerResult? result;

  String _valueToValidAllow = '';
  String _valueSavedAllow = '';
  bool? isSwitchedAllow;
  TextEditingController? _controllerAllow;
  String? _valueChangedAallow;

  TextEditingController? _controllerDue;
  String? _valueChangedDue;
  String _valueToValidDue = '';
  String _valueSavedDue = '';
  bool? isSwitchedDue;

  bool? isClick;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nameExeController = TextEditingController(text: widget.nameExercise);
    nameExe = "";
    listFile = [];
    isEdit = false;
    textEditingController =
        TextEditingController(text: widget.descriptionExercise);
    textDescription = '';
    tempList = [];
    isClick = true;
    initializeDateFormatting("en", null);
    isSwitchedAllow = false;
    isSwitchedDue = false;
    Intl.defaultLocale = 'en_US';
    setState(() {
      _valueChangedAallow = "";
      _valueChangedDue = '';
      _controllerAllow = TextEditingController(
          text: DateFormat("yyyy-MM-dd hh:mm:ss").format(
              DateFormat("yyyy/MM/dd hh:mm").parse(widget.allowSubmission!)));
      if (widget.submissionDeadline == null) {
        _controllerDue = TextEditingController(text: DateTime.now().toString());
      } else {
        _controllerDue = TextEditingController(
            text: DateFormat("yyyy-MM-dd hh:mm:ss").format(
                DateFormat("yyyy/MM/dd hh:mm")
                    .parse(widget.submissionDeadline!)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GetInfoExerciseBloc, GetInfoExerciseState>(
        builder: (context, state) {
      if (state is Empty) {
        getDetailExe();
      } else if (state is Loaded) {
        Size size = MediaQuery.of(context).size;
        tempList = state.data?.files!;
        return state.data != null
            ? Scaffold(
                backgroundColor: Colors.white,
                appBar: _appBar(
                    title: state.data?.titleExercise,
                    idCourse: state.data?.idCourse,
                    nameCourse: state.data?.nameCourse,
                    onChanged: (value) {
                      nameExe = value;
                    },
                    controller: nameExeController),
                body: SingleChildScrollView(
                  child: Container(
                    width: size.width,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: size.width / 25,
                          right: size.width / 25,
                          top: size.width / 20),
                      child: Column(
                        children: [
                          ///khung giờ nộp bài
                          isEdit == false
                              ? _header(
                                  allowSubmission: state.data?.allowSubmission,
                                  submissionDeadline:
                                      state.data?.submissionDeadline)
                              : Column(
                                  children: [
                                    /// cài đặt thời gian mở
                                    _pickDateTime(
                                        controllerDateTime: _controllerAllow,
                                        isSwitched: isSwitchedAllow,
                                        valueChange: _valueChangedAallow,
                                        initTime: widget.allowSubmission,
                                        valueSave: _valueSavedAllow,
                                        valueToValidate: _valueToValidAllow,
                                        label: "Allow submissions from",
                                        functionDatetime: (val) => setState(() {
                                              _valueChangedAallow = val;
                                            }),
                                        functionSwitch: (value) {
                                          setState(() {
                                            isSwitchedAllow = value;
                                          });
                                        }),

                                    /// cài đặt thời gian kết thúc
                                    _pickDateTime(
                                        controllerDateTime: _controllerDue,
                                        label: "Due date",
                                        isSwitched: isSwitchedDue,
                                        valueChange: _valueChangedDue,
                                        initTime: widget.submissionDeadline,
                                        functionDatetime: (val) => setState(() {
                                              _valueChangedDue = val;
                                            }),
                                        valueSave: _valueSavedDue,
                                        valueToValidate: _valueToValidDue,
                                        functionSwitch: (value) {
                                          setState(() {
                                            isSwitchedDue = value;
                                          });
                                        }),
                                  ],
                                ),

                          /// mô tả
                          _content(
                              content: state.data?.descriptionExercise == null
                                  ? ""
                                  : state.data?.descriptionExercise,
                              textEditingController: textEditingController,
                              function: (value) {
                                textDescription = value;
                              }),
                          SizedBox(
                            height: size.width / 15,
                          ),

                          ///pick file and show
                          _uploadedFile(
                              list: tempList,
                              title:
                                  "Uploaded File (${state.data?.files?.length})"),
                          SizedBox(
                            height: size.width / 15,
                          ),

                          ///gradingSummary
                          appUser?.role == "teacher"
                              ? (isEdit == false
                                  ? gradingSummary(
                                      context: context,
                                      title: "Grading summary",
                                      viewAll: "View all",
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    GradeExerciseTeacherPage(
                                                        idExercise:
                                                            widget.idExercise,
                                                        isTextPoint: state
                                                            .data?.isTextPoint,
                                                        idCourse: state
                                                            .data?.idCourse)));
                                      },
                                      totalNumberOfGradedSubmissions: state
                                          .data?.totalNumberOfGradedSubmissions,
                                      totalNumberOfSubmissions:
                                          state.data?.totalNumberOfSubmissions,
                                      totalStudentInCourse:
                                          state.data?.totalStudentInCourse,
                                    )
                                  : SizedBox.shrink())

                              /// submission
                              : InfoAnswerPage(
                                  idAccount: appUser?.iId,
                                  idAnswer: state.data?.idAnswer,
                                  submissionDeadline:
                                      state.data?.submissionDeadline,
                                  allowSubmission: state.data?.allowSubmission),
                          appUser?.role == "teacher"
                              ? (isEdit == false
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        accept(
                                            context: context,
                                            color: Colors.amber,
                                            function: () {
                                              setState(() {});
                                              isEdit = !isEdit!;
                                            },
                                            content: "Edit"),
                                        accept(
                                            context: context,
                                            color: Colors.red,
                                            function: () {
                                              AlertDialog2.yesAbortDialog(
                                                  context: context,
                                                  title: "Delete Exercise",
                                                  body:
                                                      "You want to delete exercise ${state.data!.titleExercise}",
                                                  onPressed: () {
                                                    removeExercise(
                                                        idExercise:
                                                            widget.idExercise,
                                                        failure: () =>
                                                            showCancelDelete(),
                                                        success: () =>
                                                            showSuccessDelete(
                                                                idCourse: state
                                                                    .data!
                                                                    .idCourse,
                                                                nameCourse: state
                                                                    .data!
                                                                    .nameCourse));
                                                  });
                                            },
                                            content: "Remove"),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        accept(
                                            context: context,
                                            color: Colors.red,
                                            function: () {
                                              setState(() {});
                                              Navigator.pop(context);
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailExercisePage(
                                                            idExercise: widget
                                                                .idExercise,
                                                            descriptionExercise:
                                                                widget
                                                                    .descriptionExercise,
                                                            allowSubmission: widget
                                                                .allowSubmission,
                                                            submissionDeadline:
                                                                widget
                                                                    .submissionDeadline,
                                                          )));
                                            },
                                            content: "Cancel"),
                                        accept(
                                            color: Colors.green,
                                            context: context,
                                            content: "Accept",
                                            function: () {
                                              setState(() {});
                                              print("1 ${_valueChangedAallow}");
                                              editExercise(
                                                  success: () =>
                                                      showSuccessUpdate(),
                                                  failure: () =>
                                                      showCancelUpdate(),
                                                  idCourse:
                                                      state.data?.idCourse,
                                                  idExercise: widget.idExercise,
                                                  titleExercise: nameExe,
                                                  descriptionExercise:
                                                      textDescription,
                                                  allowSubmission: isSwitchedAllow == true
                                                      ? (_valueChangedAallow == ""
                                                          ? DateTime.now()
                                                              .toString()
                                                          : DateFormat("yyyy/MM/dd hh:mm").format(
                                                              DateFormat("yyyy-MM-dd hh:mm")
                                                                  .parse(
                                                                      _valueChangedAallow!)))
                                                      : DateFormat("yyyy-MM-dd hh:mm:ss").format(
                                                          DateFormat("yyyy/MM/dd hh:mm")
                                                              .parse(widget
                                                                  .allowSubmission!)),
                                                  submissionDeadline: isSwitchedDue == true
                                                      ? (_valueChangedDue == ""
                                                          ? DateTime.now()
                                                              .toString()
                                                          : DateFormat("yyyy/MM/dd hh:mm")
                                                              .format(DateFormat("yyyy-MM-dd hh:mm").parse(_valueChangedDue!)))
                                                      : null,
                                                  fileKeep: tempList,
                                                  listFile: listFile);
                                            }),
                                      ],
                                    ))
                              : (accept(
                                  context: context,
                                  function: () {
                                    // BlocProvider(
                                    //   create: (_) => sl<GetInformationAnswerBloc>(),
                                    //   child:  SubmitExercisePage(
                                    //       idExercise:
                                    //       widget.idExercise,
                                    //       descriptionExercise: widget.descriptionExercise,
                                    //       submissionDeadline: widget.submissionDeadline,
                                    //       allowSubmission: widget.allowSubmission,
                                    //       nameExercise: widget.nameExercise,
                                    //
                                    //       titleExercise: state
                                    //           .data?.titleExercise)
                                    // );
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SubmitExercisePage(
                                                    idExercise:
                                                        widget.idExercise,
                                                    descriptionExercise: widget
                                                        .descriptionExercise,
                                                    submissionDeadline: widget
                                                        .submissionDeadline,
                                                    allowSubmission:
                                                        widget.allowSubmission,
                                                    nameExercise:
                                                        widget.nameExercise,
                                                    idAnswer:
                                                        state.data?.idAnswer,
                                                    titleExercise: state
                                                        .data?.titleExercise)));
                                  },
                                  content: "Submit")),
                          SizedBox(
                            height: size.width / 15,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Center(child: Text("Invail exercise"));
      } else if (state is Loading) {
        return SpinkitLoading();
      } else if (state is Error) {
        return Center(
          child: Text("Lỗi hệ thống"),
        );
      }
      return Container();
    });
  }

  void getDetailExe() {
    BlocProvider.of<GetInfoExerciseBloc>(context)
        .add(GetInfoExerciseEventE(idExercise: widget.idExercise));
  }

  Widget _uploadedFile({List<Files>? list, String? title}) {
    Size size = MediaQuery.of(context).size;
    return Container(
        width: size.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            isEdit == true
                ? chooseFile(
                    title: "Additional files",
                    function: () async {
                      result = await FilePicker.platform
                          .pickFiles(allowMultiple: true);
                      List<PlatformFile>? listFile1 = [];

                      if (result != null) {
                        setState(() {
                          listFile1 = result!.files;
                        });

                        listFile!.addAll(listFile1!);

                        /// duyệt mảng chỉ show 1-1
                        listFile = LinkedHashSet<PlatformFile>.from(listFile!)
                            .toList();
                      } else {
                        // User canceled the picker
                      }
                    },
                    context: context)
                : Text(
                    title!,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: size.width / 20,
                        fontWeight: FontWeight.w600),
                  ),
            SizedBox(
              height: size.width / 20,
            ),
            Container(
              width: size.width,
              height: (list!.length + listFile!.length) * size.width / 6,
              child: ListView(
                children: [
                  ListFiles(
                    list: listFile,
                    scrollPhysics: NeverScrollableScrollPhysics(),
                    isUpdate: isEdit == true ? false : true,
                  ),
                  _listFile(list: list),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _listFile({List<Files>? list}) {
    Size size = MediaQuery.of(context).size;

    return Container(
      width: size.width,

      ///  widget.list!.length > 4 ? size.width / 1.4 : widget.list!.length * size.width / 6,
      height: list!.length * size.width / 6,
      child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OpenImage(
                            url: list[index].pathname,
                            //  file: list[index],
                            originalname: list[index].originalname,
                          )),
                );
              },
              child: Container(
                height: size.width / 7,
                width: size.width / 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TypeFile.fileImage.contains(
                                list[index].originalname?.split(".").last)
                            ? Container(
                                height: size.width / 10,
                                width: size.width / 10,
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: NetworkImage(
                                            "${list[index].pathname}"),
                                        fit: BoxFit.cover)),
                              )
                            : Container(
                                height: size.width / 10,
                                width: size.width / 10,
                                decoration: BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/icons/${thumbnail(image: list[index].originalname?.split(".").last)}"),
                                        fit: BoxFit.cover)),
                              ),
                        SizedBox(
                          width: size.width / 15,
                        ),
                        _detailFile(file: list[index]),
                      ],
                    ),
                    isEdit == false
                        ? IconButton(
                            icon: Icon(Icons.arrow_circle_down),
                            onPressed: () {
                              setState(() {
                                downloadFile(
                                    url: list[index].pathname,
                                    namefile: list[index].originalname);
                              });
                            },
                          )
                        : IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              setState(() {
                                list.remove(list[index]);
                              });
                            },
                          ),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (context, index) => Divider(),
          itemCount: list.length),
    );
  }

  ///down file
  Future<bool> saveFile(String url, String fileName) async {
    Directory directory;
    try {
      if (Platform.isAndroid) {
        if (await _requestPermission(Permission.storage)) {
          directory = (await getExternalStorageDirectory())!;
          String newPath = "";
          print(directory);
          List<String> paths = directory.path.split("/");
          for (int x = 1; x < paths.length; x++) {
            String folder = paths[x];
            if (folder != "Android") {
              newPath += "/" + folder;
            } else {
              break;
            }
          }
          newPath = newPath;
          print(newPath);
          directory = Directory(newPath);
        } else {
          return false;
        }
      } else {
        if (await _requestPermission(Permission.photos) &&
            await _requestPermission(Permission.accessMediaLocation) &&
            await _requestPermission(Permission.manageExternalStorage)) {
          directory = await getTemporaryDirectory();
        } else {
          return false;
        }
      }
      File saveFile = File(directory.path + "/$fileName");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        await dio.download(url, saveFile.path,
            onReceiveProgress: (value1, value2) {
          setState(() {});
        });
        if (Platform.isIOS) {
          await ImageGallerySaver.saveFile(saveFile.path,
              isReturnPathOfIOS: true);
        }
        return true;
      }
      return false;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }

  downloadFile({String? url, String? namefile}) async {
    setState(() {});

    bool downloaded = await saveFile(url!, "${namefile!}");
    if (downloaded) {
      showSuccess();
      print("File Downloaded");
    } else {
      showCancel();
      print("Problem Downloading File");
    }
    setState(() {});
  }

  Widget _detailFile({Files? file}) {
    Size size = MediaQuery.of(context).size;
    final kb = file!.size! / 1024;
    final mb = kb / 1024;
    final fileSize =
        mb >= 1 ? "${mb.toStringAsFixed(2)} MB" : "${kb.toStringAsFixed(2)} KB";
    return Container(
      height: size.width / 7,
      width: size.width / 1.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "${file.originalname}",
            style: TextStyle(color: Colors.black, fontSize: size.width / 20),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: size.width / 5,
                child: Text(
                  "$fileSize",
                  style:
                      TextStyle(color: Colors.black, fontSize: size.width / 25),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              SizedBox(
                width: size.width / 10,
              ),
            ],
          )
          // Text("${list[index].extension}"),
          // Text("$fileSize"),
        ],
      ),
    );
  }

  Widget _content(
      {String? content,
      TextEditingController? textEditingController,
      Function(String?)? function}) {
    Size size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(top: size.width / 15),
      child: Container(
        height: size.width / 2,
        width: size.width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(size.width / 30),
            ),
            color: Colors.grey.shade300.withOpacity(0.3),
            border: Border.all(
                color: Colors.cyan.withOpacity(0.3), width: size.width / 100)),
        child: Padding(
          padding: EdgeInsets.all(size.width / 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "Description",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: size.width / 20,
                    fontWeight: FontWeight.w600),
              ),
              Container(
                height: size.width / 3.2,
                child: ListView(
                  children: [
                    TextField(
                      controller: textEditingController,
                      onChanged: function,
                      enabled: isEdit == true ? true : false,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                      ),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width / 25,
                          fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _header({String? submissionDeadline, String? allowSubmission}) {
    Size size = MediaQuery.of(context).size;

    return Container(
      height: size.width / 5,
      width: size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(size.width / 30),
        ),
        color: Colors.cyan.withOpacity(0.3),
      ),
      child: Padding(
        padding: EdgeInsets.all(size.width / 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Allow Submission: ${parseStringToTime(textTime: allowSubmission)}",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: size.width / 25,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              "Submission Deadline: ${parseStringToTime(textTime: submissionDeadline)}",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: size.width / 25,
                  fontWeight: FontWeight.w600),
            )
          ],
        ),
      ),
    );
  }

  PreferredSize _appBar(
      {String? title,
      TextEditingController? controller,
      Function(String?)? onChanged,
      String? idCourse,
      String? nameCourse}) {
    Size size = MediaQuery.of(context).size;

    return PreferredSize(
      preferredSize: Size.fromHeight(size.width / 8),
      child: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DetailCoursePage(
                          choosingPos: 2,
                          widgetId: 2,
                          nameCourse: nameCourse,
                          idCourse: idCourse,
                        )));
          },
        ),
        iconTheme: IconThemeData(
          color: Colors.black, //change your color here
        ),
        title: isEdit == false
            ? Text(
                title!,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: size.width / 15),
              )
            : TextField(
                controller: controller,
                maxLines: 1,
                onChanged: onChanged!,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                style: TextStyle(
                    color: Colors.black,
                    fontSize: size.width / 20,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: FontWeight.w700),
              ),
        centerTitle: true,
        elevation: 0,
      ),
    );
  }

  void showCancel() {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
        },
        title: "ERROR",
        description: "File download failed");
  }

  void showSuccess() {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
          Navigator.pop(context);
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => DetailCoursePage(
          //           idCourse: widget.idCourse,
          //           nameCourse: widget.nameCourse,
          //           widgetId: 2,
          //           choosingPos: 2,
          //         )));
        },
        title: "SUCCESS",
        description: "File download successful");
  }

  void showCancelDelete() {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
        },
        title: "ERROR",
        description: "Delete failed");
  }

  void showSuccessDelete({String? idCourse, String? nameCourse}) {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailCoursePage(
                        idCourse: idCourse,
                        nameCourse: nameCourse,
                        widgetId: 2,
                        choosingPos: 2,
                      )));
        },
        title: "SUCCESS",
        description: "Delete successful");
  }

  Widget _pickDateTime(
      {bool? isSwitched,
      String? initTime,
      String? valueChange,
      String? valueToValidate,
      String? valueSave,
      TextEditingController? controllerDateTime,
      Function(bool)? functionSwitch,
      Function(String)? functionDatetime,
      String? label}) {
    Size size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      height: size.width / 5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: size.width / 1.5,
            height: size.width / 5,
            child: DateTimePicker(
                type: DateTimePickerType.dateTime,
                // dateMask: 'dd MMMM, yyyy - hh:mm a',
                controller: controllerDateTime,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                //icon: Icon(Icons.event),
                dateLabelText: label,
                use24HourFormat: true,
                locale: Locale('en', 'US'),
                onChanged: functionDatetime,
                validator: (val) {
                  setState(() => valueToValidate = val ?? '');

                  return null;
                },
                onSaved: (val) {
                  setState(() => valueSave = val ?? '');
                }),
          ),
          Switch(
            value: isSwitched!,
            onChanged: functionSwitch,
            activeTrackColor: Colors.lightBlueAccent.withOpacity(0.3),
            activeColor: Colors.lightBlueAccent,
          ),
        ],
      ),
    );
  }

  void showCancelUpdate() {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
        },
        title: "ERROR",
        description: "Update failed");
  }

  void showSuccessUpdate() {
    return showPopup(
        context: context,
        function: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DetailExercisePage(
                        idExercise: widget.idExercise,
                        descriptionExercise: textDescription,
                        allowSubmission: _valueChangedAallow == ""
                            ? DateFormat("yyyy/MM/dd hh:mm").format(
                                DateFormat("yyyy-MM-dd hh:mm:ss")
                                    .parse(DateTime.now().toString()))
                            : DateFormat("yyyy/MM/dd hh:mm").format(
                                DateFormat("yyyy-MM-dd hh:mm")
                                    .parse(_valueChangedAallow!)),
                        submissionDeadline: _valueChangedDue == ""
                            ? null
                            : DateFormat("yyyy/MM/dd hh:mm").format(
                                DateFormat("yyyy-MM-dd hh:mm")
                                    .parse(_valueChangedDue!)),
                      )));
        },
        title: "SUCCESS",
        description: "Update successful");
  }
}
