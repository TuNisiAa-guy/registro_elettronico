// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spaggiari_client.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _SpaggiariClient implements SpaggiariClient {
  _SpaggiariClient(this._dio, {this.baseUrl}) {
    ArgumentError.checkNotNull(_dio, '_dio');
    this.baseUrl ??= 'https://web.spaggiari.eu/rest/v1';
  }

  final Dio _dio;

  String baseUrl;

  @override
  loginUser(loginRequest) async {
    ArgumentError.checkNotNull(loginRequest, 'loginRequest');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    _data.addAll(loginRequest.toJson() ?? <String, dynamic>{});
    final Response<Map<String, dynamic>> _result = await _dio.request(
        '/auth/login',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'POST',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = LoginResponse.fromJson(_result.data);
    return Future.value(value);
  }

  @override
  getTodayLessons(studentId) async {
    ArgumentError.checkNotNull(studentId, 'studentId');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final Response<List<dynamic>> _result = await _dio.request(
        '/students/$studentId/lessons/20191108/20191109',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    var value = _result.data
        .map((dynamic i) => Lesson.fromJson(i as Map<String, dynamic>))
        .toList();
    return Future.value(value);
  }
}