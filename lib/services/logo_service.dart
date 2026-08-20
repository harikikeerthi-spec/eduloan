import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LogoService {
  static final Map<String, String?> _cache = {};

  // Static registry mapping popular/local universities to their official domain names
  static const Map<String, String> _customDomains = {
    // USA
    'Harvard University': 'harvard.edu',
    'Massachusetts Institute of Technology (MIT)': 'mit.edu',
    'Stanford University': 'stanford.edu',
    'Yale University': 'yale.edu',
    'Princeton University': 'princeton.edu',
    'Columbia University': 'columbia.edu',
    'University of Pennsylvania (UPenn)': 'upenn.edu',
    'University of California, Berkeley': 'berkeley.edu',
    'Carnegie Mellon University (CMU)': 'cmu.edu',
    'New York University (NYU)': 'nyu.edu',
    'University of North Texas': 'unt.edu',
    'University of North Texas Health Science Center': 'unthsc.edu',
    'University of North Texas at Dallas': 'untdallas.edu',
    'University of the Cumberlands': 'ucumberlands.edu',
    'University of the Ozarks': 'ozarks.edu',
    'Oklahoma State University': 'okstate.edu',
    'University of Idaho': 'uidaho.edu',
    'Oregon State University': 'oregonstate.edu',
    'University of Northern Colorado': 'unco.edu',

    // UK
    'University of Oxford': 'ox.ac.uk',
    'University of Cambridge': 'cam.ac.uk',
    'Imperial College London': 'imperial.ac.uk',
    'London School of Economics (LSE)': 'lse.ac.uk',
    'University College London (UCL)': 'ucl.ac.uk',
    'University of Edinburgh': 'ed.ac.uk',

    // Canada
    'University of Toronto': 'utoronto.ca',
    'University of British Columbia (UBC)': 'ubc.ca',
    'McGill University': 'mcgill.ca',
    'University of Waterloo': 'uwaterloo.ca',

    // Australia
    'University of Melbourne': 'unimelb.edu.au',
    'University of Sydney': 'sydney.edu.au',
    'Australian National University (ANU)': 'anu.edu.au',
    'University of New South Wales (UNSW)': 'unsw.edu.au',

    // Europe & Asia
    'ETH Zurich': 'ethz.ch',
    'Technical University of Munich (TUM)': 'tum.de',
    'National University of Singapore (NUS)': 'nus.edu.sg',
    'Nanyang Technological University (NTU)': 'ntu.edu.sg',
    'Delft University of Technology': 'tudelft.nl',
  };

  /// Fetches a company/university logo URL dynamically using external APIs.
  static Future<String?> getLogoByName(String name) async {
    if (_cache.containsKey(name)) {
      return _cache[name];
    }
    try {
      final cleanName = name.trim();

      // 0. Check custom mapped domains first for instant resolution
      if (_customDomains.containsKey(cleanName)) {
        final domain = _customDomains[cleanName]!;
        final logo = await getValidLogoForDomain(domain);
        if (logo != null) {
          _cache[name] = logo;
          return logo;
        }
      }

      final encodedName = Uri.encodeComponent(cleanName);

      // Try 1: Utilize the comprehensive hipolabs university registry to find the exact domain
      final hipoUrl =
          'http://universities.hipolabs.com/search?name=$encodedName';
      final hipoResponse = await http
          .get(Uri.parse(hipoUrl))
          .timeout(const Duration(seconds: 4));

      if (hipoResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(hipoResponse.body);
        if (data.isNotEmpty) {
          var uniData = data.first;
          if (uniData['web_pages'] != null &&
              (uniData['web_pages'] as List).isNotEmpty) {
            String domain = uniData['web_pages'][0].toString();
            domain = domain.replaceAll(RegExp(r'^https?://'), '');
            domain = domain.replaceAll(RegExp(r'^www\.'), '');
            domain = domain.replaceAll(RegExp(r'/$'), '');
            domain = domain.split('/')[0];

            final logo = await getValidLogoForDomain(domain);
            if (logo != null) {
              _cache[name] = logo;
              return logo;
            }
          }
        }
      }

      // Try 2: Fallback to Clearbit Autocomplete
      final url =
          'https://autocomplete.clearbit.com/v1/companies/suggest?query=$encodedName';
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var match in data) {
          if (match['logo'] != null) {
            final logoUrl = match['logo'] as String;
            if (await isUrlValid(logoUrl)) {
              _cache[name] = logoUrl;
              return logoUrl;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching logo for $name: $e');
    }
    _cache[name] = null;
    return null;
  }

  static Future<String?> getValidLogoForDomain(String domain) async {
    final clearbitUrl = 'https://logo.clearbit.com/$domain';
    if (await isUrlValid(clearbitUrl)) {
      return clearbitUrl;
    }
    // Fallback to Google Favicon which resolves for almost all domains without validation
    return 'https://www.google.com/s2/favicons?sz=128&domain=$domain';
  }

  static Future<bool> isUrlValid(String url) async {
    try {
      final response = await http
          .head(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
            },
          )
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) return true;
    } catch (_) {
      try {
        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
              },
            )
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) return true;
      } catch (_) {}
    }
    return false;
  }
}
