import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateFrom(dynamic value) =>
    value is Timestamp ? value.toDate() : value as DateTime?;

class AppUser {
  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.studentNumber,
    this.photoUrl,
  });
  final String uid, fullName, email;
  final String? studentNumber, photoUrl;
  factory AppUser.fromMap(String id, Map<String, dynamic> data) => AppUser(
    uid: id,
    fullName: data['fullName'] ?? '',
    email: data['email'] ?? '',
    studentNumber: data['studentNumber'],
    photoUrl: data['photoUrl'],
  );
}

class Group {
  const Group({
    required this.id,
    required this.name,
    required this.course,
    required this.leaderId,
    required this.code,
    required this.maxMembers,
    required this.joinType,
    this.description = '',
    this.courseworkTitle = '',
    this.deadline,
    this.repositoryUrl,
    this.isLocked = false,
  });
  final String id,
      name,
      course,
      leaderId,
      code,
      description,
      courseworkTitle,
      joinType;
  final int maxMembers;
  final DateTime? deadline;
  final String? repositoryUrl;
  final bool isLocked;
  factory Group.fromMap(String id, Map<String, dynamic> data) => Group(
    id: id,
    name: data['name'] ?? '',
    course: data['course'] ?? '',
    leaderId: data['leaderId'] ?? '',
    code: data['code'] ?? '',
    description: data['description'] ?? '',
    courseworkTitle: data['courseworkTitle'] ?? '',
    maxMembers: (data['maxMembers'] ?? 1) as int,
    joinType: data['joinType'] ?? 'open',
    deadline: dateFrom(data['deadline']),
    repositoryUrl: data['repositoryUrl'],
    isLocked: data['isLocked'] ?? false,
  );
}

class Membership {
  const Membership({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    this.fullName = '',
  });
  final String id, groupId, userId, role, status, fullName;
  bool get isLeader => role == 'leader';
  factory Membership.fromMap(String id, Map<String, dynamic> data) =>
      Membership(
        id: id,
        groupId: data['groupId'] ?? '',
        userId: data['userId'] ?? '',
        role: data['role'] ?? 'member',
        status: data['status'] ?? 'active',
        fullName: data['fullName'] ?? 'Member',
      );
}

class GroupTask {
  const GroupTask({
    required this.id,
    required this.groupId,
    required this.title,
    required this.status,
    required this.priority,
    required this.createdBy,
    this.description = '',
    this.assignedTo,
    this.deadline,
  });
  final String id, groupId, title, status, priority, createdBy, description;
  final String? assignedTo;
  final DateTime? deadline;
  bool get completed => status == 'completed';
  factory GroupTask.fromMap(String id, Map<String, dynamic> data) => GroupTask(
    id: id,
    groupId: data['groupId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    status: data['status'] ?? 'notStarted',
    priority: data['priority'] ?? 'medium',
    createdBy: data['createdBy'] ?? '',
    assignedTo: data['assignedTo'],
    deadline: dateFrom(data['deadline']),
  );
}

class GroupNote {
  const GroupNote({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.updatedBy,
    this.updatedAt,
  });
  final String id, groupId, title, content, updatedBy;
  final DateTime? updatedAt;
  factory GroupNote.fromMap(String id, Map<String, dynamic> data) => GroupNote(
    id: id,
    groupId: data['groupId'] ?? '',
    title: data['title'] ?? '',
    content: data['content'] ?? '',
    updatedBy: data['updatedBy'] ?? '',
    updatedAt: dateFrom(data['updatedAt']),
  );
}

class WorkspaceFile {
  const WorkspaceFile({
    required this.id,
    required this.groupId,
    required this.name,
    required this.storagePath,
    required this.downloadUrl,
    required this.category,
    required this.uploaderId,
    required this.size,
    this.createdAt,
  });
  final String id,
      groupId,
      name,
      storagePath,
      downloadUrl,
      category,
      uploaderId;
  final int size;
  final DateTime? createdAt;
  factory WorkspaceFile.fromMap(String id, Map<String, dynamic> data) =>
      WorkspaceFile(
        id: id,
        groupId: data['groupId'] ?? '',
        name: data['filename'] ?? '',
        storagePath: data['storagePath'] ?? '',
        downloadUrl: data['downloadUrl'] ?? '',
        category: data['category'] ?? 'other',
        uploaderId: data['uploaderId'] ?? '',
        size: (data['size'] ?? 0) as int,
        createdAt: dateFrom(data['createdAt']),
      );
}

class DiscussionPost {
  const DiscussionPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.content,
    this.createdAt,
  });
  final String id, groupId, authorId, content;
  final DateTime? createdAt;
  factory DiscussionPost.fromMap(String id, Map<String, dynamic> data) =>
      DiscussionPost(
        id: id,
        groupId: data['groupId'] ?? '',
        authorId: data['authorId'] ?? '',
        content: data['content'] ?? '',
        createdAt: dateFrom(data['createdAt']),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    this.createdAt,
  });
  final String id, title, message;
  final bool isRead;
  final DateTime? createdAt;
  factory AppNotification.fromMap(String id, Map<String, dynamic> data) =>
      AppNotification(
        id: id,
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        isRead: data['isRead'] ?? false,
        createdAt: dateFrom(data['createdAt']),
      );
}
