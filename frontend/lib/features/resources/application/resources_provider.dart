import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/services/api_service.dart';
import '../domain/resource_model.dart';

final topicResourcesProvider =
    AsyncNotifierProviderFamily<TopicResourcesNotifier, List<ResourceModel>, int>(
  TopicResourcesNotifier.new,
);

class TopicResourcesNotifier extends FamilyAsyncNotifier<List<ResourceModel>, int> {
  @override
  Future<List<ResourceModel>> build(int topicId) async {
    final res = await ApiService().get('/resources/topic/$topicId') as List<dynamic>;
    return res.map((e) => ResourceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addResource({
    required String title,
    String resourceType = 'article',
    String? url,
    String? notes,
  }) async {
    await ApiService().post('/resources/', {
      'topic_id': arg,
      'title': title,
      'resource_type': resourceType,
      'url': url?.trim().isEmpty == true ? null : url?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
    });
    ref.invalidateSelf();
  }

  Future<void> updateResource(
    int resourceId, {
    String? title,
    String? resourceType,
    String? url,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (resourceType != null) payload['resource_type'] = resourceType;
    if (url != null) payload['url'] = url.trim().isEmpty ? null : url.trim();
    if (notes != null) payload['notes'] = notes.trim().isEmpty ? null : notes.trim();

    await ApiService().patch('/resources/$resourceId', payload);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(int resourceId, bool isCompleted) async {
    await ApiService().patch(
      '/resources/$resourceId/complete',
      {'is_completed': isCompleted},
    );
    ref.invalidateSelf();
  }

  Future<void> deleteResource(int resourceId) async {
    await ApiService().delete('/resources/$resourceId');
    ref.invalidateSelf();
  }
}
