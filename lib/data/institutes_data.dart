class Institute {
  final String name;
  final String state;
  final List<String> courses;
  final String type; // e.g., IIT, IIM, NIT, AIIMS, University

  const Institute({
    required this.name,
    required this.state,
    required this.courses,
    required this.type,
  });
}

class InstitutesData {
  static const List<Institute> allInstitutes = [
    // --- IITs (Indian Institutes of Technology) ---
    Institute(
      name: 'Indian Institute of Technology Bombay (IIT Bombay)',
      state: 'Maharashtra',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'B.Des', 'M.Des', 'PhD', 'M.Sc', 'MBA'],
    ),
    Institute(
      name: 'Indian Institute of Technology Delhi (IIT Delhi)',
      state: 'Delhi',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc', 'MBA', 'M.Des'],
    ),
    Institute(
      name: 'Indian Institute of Technology Madras (IIT Madras)',
      state: 'Tamil Nadu',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'BS Data Science', 'PhD', 'MBA', 'MA'],
    ),
    Institute(
      name: 'Indian Institute of Technology Kanpur (IIT Kanpur)',
      state: 'Uttar Pradesh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc', 'MBA', 'M.Des'],
    ),
    Institute(
      name: 'Indian Institute of Technology Kharagpur (IIT Kharagpur)',
      state: 'West Bengal',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'B.Arch', 'PhD', 'LLB', 'MBA', 'MHRM'],
    ),
    Institute(
      name: 'Indian Institute of Technology Roorkee (IIT Roorkee)',
      state: 'Uttarakhand',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'B.Arch', 'PhD', 'MBA', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Guwahati (IIT Guwahati)',
      state: 'Assam',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'B.Des', 'M.Des', 'PhD', 'MA'],
    ),
    Institute(
      name: 'Indian Institute of Technology Hyderabad (IIT Hyderabad)',
      state: 'Telangana',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'B.Des', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology (BHU) Varanasi',
      state: 'Uttar Pradesh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Pharma'],
    ),
    Institute(
      name: 'Indian Institute of Technology Indore (IIT Indore)',
      state: 'Madhya Pradesh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Gandhinagar (IIT Gandhinagar)',
      state: 'Gujarat',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'MA'],
    ),
    Institute(
      name: 'Indian Institute of Technology Ropar (IIT Ropar)',
      state: 'Punjab',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Bhubaneswar (IIT Bhubaneswar)',
      state: 'Odisha',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Jodhpur (IIT Jodhpur)',
      state: 'Rajasthan',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc', 'MBA'],
    ),
    Institute(
      name: 'Indian Institute of Technology Patna (IIT Patna)',
      state: 'Bihar',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Mandi (IIT Mandi)',
      state: 'Himachal Pradesh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Tirupati (IIT Tirupati)',
      state: 'Andhra Pradesh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Palakkad (IIT Palakkad)',
      state: 'Kerala',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Goa (IIT Goa)',
      state: 'Goa',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD'],
    ),
    Institute(
      name: 'Indian Institute of Technology Bhilai (IIT Bhilai)',
      state: 'Chhattisgarh',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Indian Institute of Technology Dharwad (IIT Dharwad)',
      state: 'Karnataka',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD', 'BS-MS'],
    ),
    Institute(
      name: 'Indian Institute of Technology Jammu (IIT Jammu)',
      state: 'Jammu & Kashmir',
      type: 'IIT',
      courses: ['B.Tech', 'M.Tech', 'PhD'],
    ),

    // --- IIMs (Indian Institutes of Management) ---
    Institute(
      name: 'Indian Institute of Management Ahmedabad (IIM Ahmedabad)',
      state: 'Gujarat',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-FABM', 'PGPX'],
    ),
    Institute(
      name: 'Indian Institute of Management Bangalore (IIM Bangalore)',
      state: 'Karnataka',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-Public Policy', 'EPGP'],
    ),
    Institute(
      name: 'Indian Institute of Management Calcutta (IIM Calcutta)',
      state: 'West Bengal',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGDBA', 'PGPEx'],
    ),
    Institute(
      name: 'Indian Institute of Management Lucknow (IIM Lucknow)',
      state: 'Uttar Pradesh',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-ABM', 'PGP-SM'],
    ),
    Institute(
      name: 'Indian Institute of Management Kozhikode (IIM Kozhikode)',
      state: 'Kerala',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-Finance', 'PGP-LSM'],
    ),
    Institute(
      name: 'Indian Institute of Management Indore (IIM Indore)',
      state: 'Madhya Pradesh',
      type: 'IIM',
      courses: ['PGP (MBA)', 'IPM', 'PGP-HRM'],
    ),
    Institute(
      name: 'Indian Institute of Management Shillong (IIM Shillong)',
      state: 'Meghalaya',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGPEx'],
    ),
    Institute(
      name: 'Indian Institute of Management Rohtak (IIM Rohtak)',
      state: 'Haryana',
      type: 'IIM',
      courses: ['PGP (MBA)', 'IPM'],
    ),
    Institute(
      name: 'Indian Institute of Management Ranchi (IIM Ranchi)',
      state: 'Jharkhand',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-HRM'],
    ),
    Institute(
      name: 'Indian Institute of Management Raipur (IIM Raipur)',
      state: 'Chhattisgarh',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGPWe (Working Exec)'],
    ),
    Institute(
      name: 'Indian Institute of Management Trichy (IIM Trichy)',
      state: 'Tamil Nadu',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGPBM'],
    ),
    Institute(
      name: 'Indian Institute of Management Udaipur (IIM Udaipur)',
      state: 'Rajasthan',
      type: 'IIM',
      courses: ['PGP (MBA)', 'PGP-DEM', 'GSCM'],
    ),
    Institute(
      name: 'Indian Institute of Management Kashipur (IIM Kashipur)',
      state: 'Uttarakhand',
      type: 'IIM',
      courses: ['PGP (MBA)', 'MBA (Analytics)'],
    ),

    // --- NITs (National Institutes of Technology) ---
    Institute(
      name: 'National Institute of Technology Trichy (NIT Trichy)',
      state: 'Tamil Nadu',
      type: 'NIT',
      courses: ['B.Tech', 'B.Arch', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),
    Institute(
      name: 'National Institute of Technology Karnataka (NITK Surathkal)',
      state: 'Karnataka',
      type: 'NIT',
      courses: ['B.Tech', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),
    Institute(
      name: 'National Institute of Technology Rourkela (NIT Rourkela)',
      state: 'Odisha',
      type: 'NIT',
      courses: ['B.Tech', 'B.Arch', 'M.Tech', 'MBA', 'PhD'],
    ),
    Institute(
      name: 'National Institute of Technology Warangal (NIT Warangal)',
      state: 'Telangana',
      type: 'NIT',
      courses: ['B.Tech', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),
    Institute(
      name: 'National Institute of Technology Calicut (NIT Calicut)',
      state: 'Kerala',
      type: 'NIT',
      courses: ['B.Tech', 'B.Arch', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),
    Institute(
      name: 'Visvesvaraya National Institute of Technology (VNIT Nagpur)',
      state: 'Maharashtra',
      type: 'NIT',
      courses: ['B.Tech', 'B.Arch', 'M.Tech', 'PhD'],
    ),
    Institute(
      name: 'Malaviya National Institute of Technology (MNIT Jaipur)',
      state: 'Rajasthan',
      type: 'NIT',
      courses: ['B.Tech', 'B.Arch', 'M.Tech', 'MBA', 'PhD'],
    ),
    Institute(
      name: 'Motilal Nehru National Institute of Technology (MNNIT Allahabad)',
      state: 'Uttar Pradesh',
      type: 'NIT',
      courses: ['B.Tech', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),
    Institute(
      name: 'Sardar Vallabhbhai National Institute of Technology (SVNIT Surat)',
      state: 'Gujarat',
      type: 'NIT',
      courses: ['B.Tech', 'M.Tech', 'M.Sc', 'PhD'],
    ),
    Institute(
      name: 'National Institute of Technology Kurukshetra (NIT Kurukshetra)',
      state: 'Haryana',
      type: 'NIT',
      courses: ['B.Tech', 'M.Tech', 'MBA', 'MCA', 'PhD'],
    ),

    // --- AIIMS (All India Institutes of Medical Sciences) ---
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Delhi',
      state: 'Delhi',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS', 'M.Ch', 'DM'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Jodhpur',
      state: 'Rajasthan',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS', 'MPH'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Bhubaneswar',
      state: 'Odisha',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Rishikesh',
      state: 'Uttarakhand',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS', 'M.Ch'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Bhopal',
      state: 'Madhya Pradesh',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Raipur',
      state: 'Chhattisgarh',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS'],
    ),
    Institute(
      name: 'All India Institute of Medical Sciences (AIIMS) Patna',
      state: 'Bihar',
      type: 'Medical',
      courses: ['MBBS', 'B.Sc Nursing', 'MD', 'MS'],
    ),

    // --- Central Universities ---
    Institute(
      name: 'Jawaharlal Nehru University (JNU)',
      state: 'Delhi',
      type: 'Central University',
      courses: ['BA (Hons)', 'MA', 'M.Phil', 'PhD', 'M.Sc'],
    ),
    Institute(
      name: 'Banaras Hindu University (BHU)',
      state: 'Uttar Pradesh',
      type: 'Central University',
      courses: ['BA', 'B.Sc', 'B.Com', 'MA', 'M.Sc', 'M.Com', 'PhD', 'B.Tech'],
    ),
    Institute(
      name: 'University of Delhi (DU)',
      state: 'Delhi',
      type: 'Central University',
      courses: ['BA', 'B.Sc', 'B.Com', 'MA', 'M.Sc', 'M.Com', 'PhD', 'LLB'],
    ),
    Institute(
      name: 'Aligarh Muslim University (AMU)',
      state: 'Uttar Pradesh',
      type: 'Central University',
      courses: ['BA', 'B.Sc', 'B.Tech', 'MBBS', 'MA', 'M.Sc'],
    ),
    Institute(
      name: 'Jamia Millia Islamia',
      state: 'Delhi',
      type: 'Central University',
      courses: ['BA', 'B.Sc', 'B.Tech', 'B.Arch', 'MBA', 'MA', 'M.Sc'],
    ),
    Institute(
      name: 'University of Hyderabad',
      state: 'Telangana',
      type: 'Central University',
      courses: ['M.Sc', 'MA', 'M.Tech', 'PhD'],
    ),
    Institute(
      name: 'Pondicherry University',
      state: 'Puducherry',
      type: 'Central University',
      courses: ['M.Sc', 'MA', 'MBA', 'M.Tech', 'PhD'],
    ),

    // --- State Universities ---
    Institute(
      name: 'Anna University',
      state: 'Tamil Nadu',
      type: 'State University',
      courses: ['BE', 'B.Tech', 'ME', 'M.Tech', 'MCA', 'MBA'],
    ),
    Institute(
      name: 'Jadavpur University',
      state: 'West Bengal',
      type: 'State University',
      courses: ['BE', 'B.Tech', 'BA', 'B.Sc', 'ME', 'M.Tech', 'MA'],
    ),
    Institute(
      name: 'University of Mumbai',
      state: 'Maharashtra',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'B.Com', 'BE', 'MA', 'M.Sc'],
    ),
    Institute(
      name: 'Savitribai Phule Pune University',
      state: 'Maharashtra',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'B.Com', 'ME', 'M.Tech', 'MBA'],
    ),
    Institute(
      name: 'University of Calcutta',
      state: 'West Bengal',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'B.Com', 'B.Tech', 'MA', 'M.Sc'],
    ),
    Institute(
      name: 'University of Madras',
      state: 'Tamil Nadu',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'B.Com', 'MA', 'M.Sc', 'MCA', 'MBA'],
    ),
    Institute(
      name: 'Bangalore University',
      state: 'Karnataka',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'B.Com', 'BE', 'MBA', 'MCA'],
    ),
    Institute(
      name: 'Osmania University',
      state: 'Telangana',
      type: 'State University',
      courses: ['BA', 'B.Sc', 'BE', 'ME', 'MBA', 'MCA'],
    ),

    // --- Private Universities & Others ---
    Institute(
      name: 'Birla Institute of Technology and Science (BITS) Pilani',
      state: 'Rajasthan',
      type: 'Private University',
      courses: ['BE', 'B.Pharm', 'M.Sc (Hons)', 'MBA', 'PhD'],
    ),
    Institute(
      name: 'Vellore Institute of Technology (VIT)',
      state: 'Tamil Nadu',
      type: 'Private University',
      courses: ['B.Tech', 'M.Tech', 'MCA', 'MBA', 'PhD'],
    ),
    Institute(
      name: 'Manipal Academy of Higher Education (MAHE)',
      state: 'Karnataka',
      type: 'Private University',
      courses: ['B.Tech', 'MBBS', 'BDS', 'B.Arch', 'MBA', 'M.Tech'],
    ),
    Institute(
      name: 'Amity University',
      state: 'Uttar Pradesh',
      type: 'Private University',
      courses: ['B.Tech', 'MBA', 'BBA', 'BA', 'B.Sc', 'LLB'],
    ),
    Institute(
      name: 'SRM Institute of Science and Technology',
      state: 'Tamil Nadu',
      type: 'Private University',
      courses: ['B.Tech', 'M.Tech', 'MBA', 'MBBS', 'B.Sc'],
    ),
    Institute(
      name: 'Thapar Institute of Engineering and Technology',
      state: 'Punjab',
      type: 'Deemed University',
      courses: ['BE', 'ME', 'M.Tech', 'MBA', 'PhD'],
    ),
    Institute(
      name: 'Symbiosis International University',
      state: 'Maharashtra',
      type: 'Private University',
      courses: ['BBA', 'MBA', 'LLB', 'BA', 'B.Sc', 'B.Tech'],
    ),
    Institute(
      name: 'Christ University',
      state: 'Karnataka',
      type: 'Private University',
      courses: ['BBA', 'B.Com', 'BA', 'B.Sc', 'MBA', 'MCA'],
    ),
    Institute(
      name: 'Indian Institute of Science (IISc) Bangalore',
      state: 'Karnataka',
      type: 'Research',
      courses: ['BS (Research)', 'M.Tech', 'M.Des', 'M.Mgt', 'PhD'],
    ),
    Institute(
      name: 'Tata Institute of Fundamental Research (TIFR)',
      state: 'Maharashtra',
      type: 'Research',
      courses: ['M.Sc', 'PhD', 'Integrated PhD'],
    ),
    Institute(
      name: 'Indian Statistical Institute (ISI) Kolkata',
      state: 'West Bengal',
      type: 'Research',
      courses: ['B.Stat', 'B.Math', 'M.Stat', 'M.Math', 'M.Tech'],
    ),
  ];
}
