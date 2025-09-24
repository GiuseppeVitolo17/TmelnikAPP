import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project.dart';

class ProjectService {
  static const String _projectsKey = 'projects';
  static ProjectService? _instance;
  static ProjectService get instance => _instance ??= ProjectService._();
  
  ProjectService._();

  Future<List<Project>> getAllProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getStringList(_projectsKey) ?? [];
      
      return projectsJson
          .map((json) => Project.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error loading projects: $e');
      return [];
    }
  }

  Future<Project?> getProjectById(String id) async {
    try {
      final projects = await getAllProjects();
      return projects.firstWhere(
        (project) => project.id == id,
        orElse: () => throw Exception('Project not found'),
      );
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  Future<bool> addProject(Project project) async {
    try {
      final projects = await getAllProjects();
      projects.add(project);
      return await _saveProjects(projects);
    } catch (e) {
      print('Error adding project: $e');
      return false;
    }
  }

  Future<bool> updateProject(Project project) async {
    try {
      final projects = await getAllProjects();
      final index = projects.indexWhere((p) => p.id == project.id);
      
      if (index == -1) {
        print('Project not found for update');
        return false;
      }
      
      projects[index] = project;
      return await _saveProjects(projects);
    } catch (e) {
      print('Error updating project: $e');
      return false;
    }
  }

  Future<bool> deleteProject(String id) async {
    try {
      final projects = await getAllProjects();
      projects.removeWhere((project) => project.id == id);
      return await _saveProjects(projects);
    } catch (e) {
      print('Error deleting project: $e');
      return false;
    }
  }

  Future<List<Project>> getProjectsByStatus(ProjectStatus status) async {
    try {
      final projects = await getAllProjects();
      return projects.where((project) => project.status == status).toList();
    } catch (e) {
      print('Error filtering projects by status: $e');
      return [];
    }
  }

  Future<bool> _saveProjects(List<Project> projects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = projects
          .map((project) => jsonEncode(project.toJson()))
          .toList();
      
      return await prefs.setStringList(_projectsKey, projectsJson);
    } catch (e) {
      print('Error saving projects: $e');
      return false;
    }
  }

  Future<int> getProjectCount() async {
    final projects = await getAllProjects();
    return projects.length;
  }

  Future<int> getProjectCountByStatus(ProjectStatus status) async {
    final projects = await getProjectsByStatus(status);
    return projects.length;
  }

  Future<void> clearAllProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_projectsKey);
    } catch (e) {
      print('Error clearing projects: $e');
    }
  }
}
